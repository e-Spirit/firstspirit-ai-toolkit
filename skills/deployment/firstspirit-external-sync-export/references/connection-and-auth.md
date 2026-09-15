# Connection and authentication

Gates 2 and 3: **reach the server**, then **authenticate**. Getting the
connection mode wrong looks like a network/transport error; getting auth wrong
looks like a login error. They are distinct — read the message.

## Connection options

fs-cli's global connection options (before the command word):

| Option | Meaning | Note |
|---|---|---|
| `-h`, `--host` | server host | hostname only, no scheme |
| `-port` | port | default `8000`; Cloud/HTTP(S) is `443` |
| `-c`, `--conn-mode` | `HTTP` \| `HTTPS` \| `SOCKET` | default `HTTP` |
| `-sz`, `--servletzone` | servlet zone | default `/` |
| `-u`, `--user` | FirstSpirit login | |
| `-pwd`, `--password` | password | **never inline in a shared shell** |
| `-p`, `--project` | project **name** | not the numeric id |

### Choosing the connection mode

- **`SOCKET`** — the classic direct socket connection (historically port
  `9000`). For self-hosted servers exposing the socket port.
- **`HTTP`** — builds `http://host:port`. For servers reachable over plain HTTP.
- **`HTTPS`** — builds `https://host:port` (and `wss://` for the websocket
  channel). **Required for FirstSpirit Cloud** and any TLS-terminating
  front-end.

**Cloud symptom if you use the default `HTTP` on 443:** the request hits the AWS
load balancer as plaintext and is rejected before FirstSpirit ever sees it:

```
IOException: Unexpected HTTP state: (400) … server=awselb/2.0 …
http://<host>:443/servlet/ClientIO/…
```

Switch to `-c HTTPS`. The websocket channel then connects
(`wss://<host>/websocket/ClientIO/… successfully connected`) and you progress to
the auth gate.

> A quick out-of-band check of the host tells you what you're dealing with:
> `curl -sSI https://<host>/` on a Cloud instance 302-redirects to
> `https://sso-<stage>.e-spirit.hosting/auth/realms/<realm>/…` — i.e. it is
> **Keycloak-fronted**, so HTTPS mode is mandatory.

## Authentication

Pass a FirstSpirit login valid for that instance via `-u` / `-pwd`. On a
**Cloud** instance the login is the account in the instance's Keycloak realm
(username is typically the email); fs-cli's HTTPS connection performs the login,
so a normal user/password works — you do **not** hand fs-cli an OAuth token.

Failure at this gate, *after* the transport connects, is:

```
INFO  FSHttpClient 'WebsocketFSHttpClient(wss://…)' successfully connected.
ERROR couldn't authenticate!
de.espirit.firstspirit.server.authentication.AuthenticationException: couldn't authenticate!
```

That means transport is fine and the **credentials** are wrong/placeholder — fix
the login, not the connection mode.

### Handle the password without exposing it

Never type the password into a command that lands in shell history, a shared
terminal, or a log. Read it from a file the operator owns, and redact it from
anything you print.

```bash
# the operator creates this once, with their own values; you never read it back
cat > ~/.fs-cli-creds.env <<'EOF'
FS_USER=<login>
FS_PWD=<password>
EOF
chmod 600 ~/.fs-cli-creds.env
```

```bash
# at run time: source it, use the vars, redact on the way out
set -a; . ~/.fs-cli-creds.env; set +a
fs-cli … -u "$FS_USER" -pwd "$FS_PWD" … 2>&1 | sed -E "s/${FS_PWD//\//\\/}/***/g"
```

Notes:
- The `<<'EOF'` (quoted heredoc) stops the shell expanding `$` in the password.
- Any pre-existing project `.env` with a different variable naming
  (`FS_USERNAME` / `FS_PASSWORD`, `FS_REST_BASE_URL`, `FS_PROJECT_ID`) is fine —
  map its names onto `-u` / `-pwd`. Confirm its **non-secret** fields (base URL,
  project id) point at the intended server before trusting its secrets.
- `-pwd` has a documented default of `Admin`; never rely on it.

## Test before you export

`fs-cli … test` connects (and, with `-p`, opens the project) without exporting —
use it to separate the three gates cleanly:

```bash
set -a; . ~/.fs-cli-creds.env; set +a
fs-cli -h <host> -port 443 -c HTTPS -u "$FS_USER" -pwd "$FS_PWD" -p "<Project Name>" test
```

Success looks like:

```
INFO Connected to FirstSpirit server at <host> of version <build> (ISOLATED)
INFO Test was successful
```

Only then run the export (`export-command.md`).

---
*Sources: fs-cli 4.8.9 `help`; a verified HTTPS/Keycloak connection to a
FirstSpirit 5.2.260815 Cloud instance (2026-08-03). Cloud identity specifics are
owned by the FirstSpirit Cloud documentation (identity and access).*
