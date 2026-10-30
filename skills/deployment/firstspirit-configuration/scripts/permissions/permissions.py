#!/usr/bin/env python3
"""permissions.py: set permissions from a role policy, safely. plan, apply, verify, report.

apply sets, for every group the policy names, exactly the permission set the policy gives it on every store root: rights
the group has and the policy does not list are removed, also on a store the policy does not mention for that group. Groups the policy does not name are left alone. It needs a user who may
change permissions in the project (a project administrator); run `plan` first and read it.

  permissions.py report                  print the project's current permissions (read-only)
  permissions.py plan   [--profile P]    what would change (read-only)
  permissions.py apply  [--profile P] --yes   apply the plan, then read back and verify
  permissions.py verify [--profile P]    exit 1 if the project differs from the policy

Environment: FS_HOST FS_USERNAME FS_PASSWORD FS_PROJECT (the project NAME). Optional: FS_SCHEME (https; http for a local
server), FS_PORT (443 for https, 80 for http).
Options: --policy FILE (default permissions/policy.json; permissions/policy.local.json is merged over it),
         --report-file FILE  use a saved `report` output instead of the server (offline plan; apply is refused).

How it works: report.bsh and apply.bsh run in the project through the REST execute endpoint (as a throwaway script that
is deleted afterwards). Plan = policy minus the current state; nothing is guessed. Only groups named in the policy are
changed, protected groups (Everyone, Administrators*) never. Admin groups have implicit rights and are not diffed. A
workflow the policy names must exist in the project's Template Store (report lists them as WORKFLOW lines); plan stops on
an unknown one before anything is applied.
Exit codes: 0 ok / in sync, 1 differences (verify), 2 error in the policy or the call.
"""
import argparse, base64, fnmatch, json, os, pathlib, re, secrets, sys, urllib.request, urllib.error

HERE = pathlib.Path(__file__).resolve().parent.parent
ALL_PERMS = ["CAN_SEE", "CAN_READ", "CAN_CHANGE", "CAN_APPEND_FOLDER", "CAN_APPEND_LEAF", "CAN_DELETE_FOLDER",
             "CAN_DELETE_LEAF", "CAN_CHANGE_PERMISSION", "CAN_RELEASE", "CAN_META_SEE", "CAN_META_CHANGE"]

class Fail(Exception):
    pass

# ---------------------------------------------------------------- policy
def deep_merge(a, b):
    out = dict(a)
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict): out[k] = deep_merge(out[k], v)
        elif isinstance(v, list) and isinstance(out.get(k), list): out[k] = out[k] + [x for x in v if x not in out[k]]
        else: out[k] = v
    return out

def load_policy(path, profile):
    p = pathlib.Path(path)
    if not p.exists(): raise Fail(f"policy {p} not found (copy permissions/policy.example.json)")
    pol = json.loads(p.read_text())
    local = p.with_name("policy.local.json")
    if local.exists(): pol = deep_merge(pol, json.loads(local.read_text()))
    if profile:
        if profile not in pol.get("profiles", {}): raise Fail(f"profile {profile} is not in the policy")
        pol = deep_merge(pol, pol["profiles"][profile])
    pol.setdefault("protectedGroups", ["Everyone", "Administrators*"])
    if pol.get("version") != 1: raise Fail("policy version must be 1")
    return pol

def is_protected(pol, name):
    return any(fnmatch.fnmatch(name, pat) for pat in pol["protectedGroups"])

def check_name(kind, name):
    """Group and workflow names travel to the scripts as |-, comma- and newline-delimited text."""
    if not name or any(c in name for c in "|,\n\r"): raise Fail(f"{kind} name {name!r} is empty or contains | , or a line break, which the tool cannot carry")

def expand(perms):
    out = set()
    for x in perms:
        if x == "ALL": out.update(ALL_PERMS)
        elif x in ALL_PERMS: out.add(x)
        else: raise Fail(f"unknown permission {x}")
    return out

def desired(pol):
    """({(store, group): set(perms)}, {(store, workflow): set(groups)}, set of groups the policy names)"""
    perms, wfs, names = {}, {}, set()
    for key in ("groups", "storeKinds"):
        if not isinstance(pol.get(key), dict): raise Fail(f"the policy has no {key} object")
    for role in pol.get("permissions", {}):
        if role not in pol["groups"]: raise Fail(f"permissions names the role {role}, which has no groups entry (typo?)")
    for role, groups in pol["groups"].items():
        for g in groups:
            check_name("group", g)
            if is_protected(pol, g): raise Fail(f"the policy names the protected group {g}")
            names.add(g)
            for kind, plist in pol.get("permissions", {}).get(role, {}).items():
                if kind not in pol["storeKinds"]: raise Fail(f"unknown store kind {kind}")
                for store in pol["storeKinds"][kind]:
                    perms.setdefault((store, g), set()).update(expand(plist))
    for w in pol.get("workflows", []):
        check_name("workflow", w["workflow"])
        gs = set()
        for role in w["roles"]:
            if role not in pol["groups"]: raise Fail(f"workflow {w['workflow']}: unknown role {role}")
            gs.update(pol["groups"][role])
        wfs.setdefault((w["store"], w["workflow"]), set()).update(gs)
    return perms, wfs, names

# ---------------------------------------------------------------- state
def parse_report(text):
    groups, perms, wfs, inherit, workflows = {}, {}, {}, {}, set()
    for line in re.split(r"\[INFO\] |\n", text):
        line = line.strip()
        if not line: continue
        p = line.split("|")
        if p[0] == "GROUP" and len(p) >= 4: groups[p[1]] = {"external": p[2] == "external", "admin": p[3] == "admin"}
        elif p[0] == "PERM" and len(p) >= 4: perms[(p[1], p[2])] = set(x for x in p[3].split(",") if x)
        elif p[0] == "WFPERM" and len(p) >= 4: wfs[(p[1], p[2])] = set(x for x in p[3].split(",") if x)
        elif p[0] == "WFINHERIT" and len(p) >= 3: inherit[p[1]] = p[2] == "true"
        elif p[0] == "WORKFLOW" and len(p) >= 2: workflows.add(p[1])
    if not groups: raise Fail("the report has no GROUP lines; it did not run or could not be read")
    return {"groups": groups, "perms": perms, "wfs": wfs, "inherit": inherit, "workflows": workflows}

def plan(pol, state):
    want_p, want_w, names = desired(pol)
    ops, notes, errors = [], [], []
    ext = pol.get("externalNames", {})
    for g, e in ext.items():
        if any(c in e for c in "|\n\r"): raise Fail(f"externalNames[{g}] contains | or a line break, which the tool cannot carry")
    for g in sorted(names):
        if g not in state["groups"]:
            if g in ext and not ext[g].startswith("<"): ops.append(("GROUP", f"GROUP|{g}|{ext[g]}", f"create external group {g}"))
            else: errors.append(f"group {g} does not exist and policy.local.json has no externalNames entry for it")
    for (store, g), want in sorted(want_p.items()):
        info = state["groups"].get(g)
        if info and info["admin"]: notes.append(f"{g}: admin group, implicit rights, not diffed"); continue
        have = state["perms"].get((store, g), set()) if info else set()
        if have != want:
            add, rem = sorted(want - have), sorted(have - want)
            ops.append(("PERM", f"PERM|{store}|{g}|{','.join(sorted(want))}", f"{store} {g}: +{add} -{rem}"))
    for g in sorted(names):                                   # a named group keeps nothing on stores its role does not cover
        info = state["groups"].get(g)
        if not info or info["admin"]: continue
        for store in sorted(s for (s, g2) in state["perms"] if g2 == g and (s, g) not in want_p):
            ops.append(("PERM", f"PERM|{store}|{g}|", f"{store} {g}: +[] -{sorted(state['perms'][(store, g)])} (the policy gives this group nothing on this store)"))
    if want_w and not state["workflows"]:
        notes.append("the report has no WORKFLOW lines (older report.bsh?); whether the policy's workflows exist is not checked")
    for (store, wf), want in sorted(want_w.items()):
        if state["workflows"] and wf not in state["workflows"]:
            errors.append(f"workflow {wf} is not in the project's Template Store (it has: {', '.join(sorted(state['workflows']))}); install the module that provides it or take it out of the policy"); continue
        have = state["wfs"].get((store, wf), set())
        inherits = state["inherit"].get(store, False)
        if inherits:
            notes.append(f"{store}: inherits its workflow permissions now; apply switches it to its own set (also when the inherited groups already match), and workflows the policy does not list for this store lose their inherited authorisation")
        if have != want or inherits:
            extra = sorted(have - want)
            if extra: notes.append(f"{store} {wf}: groups {extra} may start it and are not in the policy; they are kept only if listed")
            ops.append(("WFPERM", f"WFPERM|{store}|{wf}|{','.join(sorted(want))}", f"{store} {wf}: allowed {sorted(have)} -> {sorted(want)}"))
    return ops, sorted(set(notes)), errors

# ---------------------------------------------------------------- server
class Server:
    def __init__(self):
        for v in ("FS_HOST", "FS_USERNAME", "FS_PASSWORD", "FS_PROJECT"):
            if not os.environ.get(v): raise Fail(f"set {v}")
        scheme = os.environ.get("FS_SCHEME", "https")
        if scheme not in ("https", "http"): raise Fail("FS_SCHEME must be https or http")
        port = os.environ.get("FS_PORT", "443" if scheme == "https" else "80")
        default_port = port == ("443" if scheme == "https" else "80")
        self.base = f"{scheme}://{os.environ['FS_HOST']}" + ("" if default_port else f":{port}") + "/rest/v1"
        tok = base64.b64encode(f"{os.environ['FS_USERNAME']}:{os.environ['FS_PASSWORD']}".encode()).decode()
        self.auth = {"Authorization": f"Basic {tok}"}
        self.pid = None

    def call(self, method, path, body=None, ctype="application/json"):
        data = body.encode() if isinstance(body, str) else body
        req = urllib.request.Request(self.base + path, data=data, method=method, headers={**self.auth, "Content-Type": ctype})
        try:
            with urllib.request.urlopen(req, timeout=120) as r: return r.status, r.read().decode()
        except urllib.error.HTTPError as e: return e.code, e.read().decode()
        except urllib.error.URLError as e: raise Fail(f"cannot reach {self.base}: {e.reason}")

    def project_id(self):
        if self.pid: return self.pid
        st, body = self.call("GET", "/projects/")
        if st != 200: raise Fail(f"cannot list projects (HTTP {st})")
        d = json.loads(body); d = d if isinstance(d, list) else d.get("content", [])
        hit = [p for p in d if p.get("name") == os.environ["FS_PROJECT"]]
        if len(hit) != 1: raise Fail(f"project {os.environ['FS_PROJECT']!r} not found, or not unique")
        self.pid = hit[0]["id"]; return self.pid

    def run(self, bsh_file, inputs):
        """Run a script file in the project as a throwaway script; return the response body of a successful run."""
        pid = self.project_id(); name = "zz_perm_" + secrets.token_hex(4)
        st, body = self.call("GET", f"/projects/{pid}/template-sets/")
        if st != 200: raise Fail(f"cannot list template sets (HTTP {st}): {body[:200]}")
        ts = json.loads(body); ts = ts if isinstance(ts, list) else ts.get("content", [])
        if not ts: raise Fail("no template set to attach the script to")
        st, body = self.call("POST", f"/projects/{pid}/scripts/", json.dumps({"name": name, "type": "MENU", "location": "/"}))
        if st >= 300: raise Fail(f"cannot create the script (HTTP {st}): {body[:200]}")
        try:
            st, body = self.call("PUT", f"/projects/{pid}/scripts/{name}/template-sets/{ts[0]['uid']}", (HERE / "permissions" / bsh_file).read_text(), "text/plain")
            if st >= 300: raise Fail(f"cannot upload the script (HTTP {st}): {body[:200]}")
            st, body = self.call("POST", f"/projects/{pid}/scripts/{name}/execute", json.dumps(inputs))
            if st >= 300:
                m = re.search(r"Target exception: ([^\\]*?)(\\n|\"|$)", body)
                raise Fail("the script failed: " + (m.group(1) if m else body[:600]))
            return body
        finally:
            st, _ = self.call("DELETE", f"/projects/{pid}/scripts/{name}")
            if st >= 300: print(f"warning: could not delete the throwaway script {name} (HTTP {st}); remove it in the Template Store", file=sys.stderr)

def get_state(args):
    if args.report_file: return parse_report(pathlib.Path(args.report_file).read_text())
    return parse_report(Server().run("report.bsh", {}))

# ---------------------------------------------------------------- commands
def show(ops, notes, errors):
    for e in errors: print(f"ERROR  {e}")
    for n in notes: print(f"NOTE   {n}")
    for op in ops: print(f"CHANGE {op[2]}")
    print(f"plan: {len(ops)} change(s), {len(errors)} error(s)")

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["report", "plan", "apply", "verify"])
    ap.add_argument("--policy", default=str(HERE / "permissions" / "policy.json"))
    ap.add_argument("--profile"); ap.add_argument("--yes", action="store_true"); ap.add_argument("--report-file")
    args = ap.parse_args()
    try:
        if args.command == "report":
            body = Server().run("report.bsh", {}) if not args.report_file else pathlib.Path(args.report_file).read_text()
            print(re.sub(r"\[INFO\] ", "\n", body).strip()); return 0
        pol = load_policy(args.policy, args.profile)
        ops, notes, errors = plan(pol, get_state(args))
        show(ops, notes, errors)
        if errors: return 2
        if args.command == "plan": return 0
        if args.command == "verify": return 1 if ops else 0
        if args.report_file: raise Fail("apply needs the server, not --report-file")
        if not ops: print("apply: nothing to do"); return 0
        if not args.yes: print("apply: add --yes to carry out these changes"); return 2
        srv = Server()
        print(f"apply: project {os.environ['FS_PROJECT']!r} on {os.environ['FS_HOST']}")
        out = srv.run("apply.bsh", {"ops": "\n".join(o[1] for o in ops)})
        print("apply:", re.sub(r"\[INFO\] ", "", out).strip())
        ops2, notes2, errors2 = plan(pol, get_state(args))
        if ops2 or errors2:
            show(ops2, notes2, errors2); print("apply: the project still differs from the policy after applying"); return 1
        print("apply: verified, the project matches the policy"); return 0
    except Fail as e:
        print(f"permissions.py: {e}", file=sys.stderr); return 2

if __name__ == "__main__":
    sys.exit(main())
