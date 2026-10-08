# Identity & access — Keycloak, groups, SSO

How users, permissions, and single sign-on work on FirstSpirit Cloud, and the
constraints that shape a project's access plan. A **planning** reference — the
click-by-click Keycloak admin steps live in the official User Management doc (and
a future config/admin skill); this file is the model, the rules, and the gotchas.

## Keycloak is the identity layer

FirstSpirit Cloud uses **Keycloak** as its identity provider for authentication
and single sign-on.

- **One realm per customer**, and realms are **isolated** — one realm cannot see
  another's users or data. (Partner companies get their own realm too — see
  Federations.)
- Hosts (literal, keep verbatim): admin console under
  `sso.e-spirit.hosting/auth/...`; the account/activation URL is
  `https://<customer>-account.e-spirit.hosting` (fallback
  `https://accounts.e-spirit.cloud/`, which asks for the customer name); the app
  login URL is `https://<customer>.e-spirit.hosting`.
- **Username = the user's business email address** — the same value goes in both
  the username and email fields. Plan on corporate email identities, not
  handles.
- **Activation is self-serve by email:** a new user hits "Forgot Password" at the
  account URL, gets a verification mail, and sets their password under *Account
  security → Signing in*. Keycloak does **not** send an automatic activation
  confirmation.
- **First user:** for a **new customer**, the first account is created
  automatically (no request) and gets the **User-Manager** role. An existing
  customer requests a first user from **Support** (`support@rezolve.com` /
  `support.rezolve.com`).

## Two Keycloak roles (distinct from FirstSpirit permissions)

Roles here are about **managing identity**, not about what you can do in a
FirstSpirit project (that's groups, below).

| Role | What it governs | Rules to plan around |
| --- | --- | --- |
| **User-Manager** | Can create users and assign permissions | **≥1 required per realm**; **cannot be assigned to a group** (so there's no "user-admin group"); the first customer user gets it automatically; give it only to people with a real user-management function |
| **password-user** | Whether a user can set a **local password** in Keycloak (needed for **FS-CLI / direct API** auth) | **Assigned to all users by default**; revoking it disables local-password auth for that user **but not** their SSO/IdP login |

## Permissions are group-based (not role-based)

The single most important access fact on the Cloud:

- FirstSpirit permissions are assigned **exclusively via groups** — a user's
  rights are **inherited** from the groups they belong to.
- **Manage users only in Keycloak.** If a user is instead added to an **external
  group inside FirstSpirit**, they **lose the ability to log in** — a real
  footgun. Keep membership changes in Keycloak.

### Group mapping — get the names exactly right
An external group in FirstSpirit links to a Keycloak group **only when the names
are identical**:

- The FirstSpirit external group's **"External name"** must match the Keycloak
  group name **exactly** — **case-sensitive** (both systems are).
- Mapping is **not automatic**: creating or renaming a group in Keycloak is **not
  propagated** to FirstSpirit — you maintain both sides.
- A mismatch grants **nothing**, silently. This is the most common access bug.

### Default group pattern
Cloud projects are provisioned with a standard set of groups (already in place
for most customers). Pattern — `<customer>` is the customer slug:

| Group | Purpose |
| --- | --- |
| `<customer>-users-[dev/qa/prod]` | Base access per stage/environment |
| `<customer>-chiefeditors` | Extended editorial permissions (incl. release) |
| `<customer>-editors` | Classic editors — **no release** permission |
| `<customer>-developer` | Template developers (+ Git access) |
| `<customer>-git-user` | Git access |
| `<customer>-projectadmins-[dev/qa/prod]` | **Project** admin per stage (not server admin) |
| `<customer>-template-distribution` | **Template Transport** across stages |

- **Creating a group** is possible for a User-Manager; an **empty new group
  auto-deletes** after a preset time.
- **Deleting a group is *not* self-service** — no User-Manager can delete a
  group; it takes a **Support request** (also in the ticket list in
  [cloud-constraints.md](cloud-constraints.md)).
- **Deleting a user** is permanent (no restore); you **cannot** delete users you
  don't own (partner-org or FirstSpirit-employee users).

**Best practice:** model access as **groups mapped to project permissions per
stage**; keep all membership in **Keycloak**; grant `template-distribution` and
`projectadmins` deliberately (they gate PROD and project admin); remember there is
**no Server Admin** role for customers — server tasks are a Support request (see
[cloud-constraints.md](cloud-constraints.md)).

## External identity provider (SSO / IdP)

Customers can connect their **own IdP** so staff sign in with corporate
credentials (SSO), with automatic user creation on first login.

- **Protocols:** **OIDC** (preferred) and **SAML**.
- **SAML in Azure:** setup support **cannot be provided** for the SAML
  configuration in Azure. If the customer is Azure/Entra-based, plan for **OIDC**.
- **MFA:** FirstSpirit itself **does not provide MFA** — you get it by connecting
  **your own IdP**, where the MFA step happens. If MFA is a requirement, an **IdP
  connection is mandatory**.
- **Group assignment is *not* automated by the IdP.** The IdP passes identity
  (ID, email, name) and auto-creates the Keycloak user, but it has **no knowledge
  of FirstSpirit permissions** — a **User-Manager must add each user to groups
  manually**. Don't promise SCIM-style group provisioning.
- **Existing (pre-IdP) users** are prompted to **link** their account to the IdP
  on first IdP login (a one-time "Add to existing account" + email verification).

**Setup is a Support-driven exchange** (not a self-service toggle):

1. Raise a request with **Support** stating the protocol (OIDC or SAML).
2. Ensure **email works in your Keycloak realm** — all users (incl. test users)
   must have a reachable email address.
3. FirstSpirit sends the **URIs** — a **Redirect URI** (OIDC/SAML) and, for SAML,
   an **Application ID URI** of the form
   `https://sso.e-spirit.hosting/auth/realms/<your-realm>`.
4. You configure your IdP and return the details — **OIDC:** metadata/config URL,
   ClientID, ClientSecret, the email for the User-Manager role; **SAML:** the
   token emails, the Federation Metadata URL, the User-Manager email.
5. FirstSpirit defines the connection, then runs a **test workshop** to verify
   access.

## Federations (partner-realm access)

When a partner company works on a customer's Cloud, their **separate realm** is
connected to the customer's — this is a **federation**.

- **The customer must request the federation from Support** — the **partner
  cannot** request it.
- Once connected, partner users appear in the customer's realm **with no access
  rights** until a User-Manager adds them to groups.

## Access-planning checklist

- **One realm per customer**; confirm the customer slug and stage naming up front.
- **Username = business email**; plan corporate email identities.
- **Model permissions as groups**, per stage; match Keycloak ↔ FirstSpirit group
  names **exactly** (case-sensitive); maintain **membership in Keycloak only**.
- Ensure **≥1 User-Manager**; keep **password-user** for anyone needing FS-CLI/API
  local auth.
- Decide **SSO** early: **OIDC** (preferred), **not SAML-in-Azure**; if **MFA** is
  required, an **IdP connection is mandatory**; remember **group assignment stays
  manual**.
- **Federations, group deletion, and first-user (existing customer)** are
  **Support requests** — plan lead time.
- Grant **template-distribution** / **projectadmins** intentionally — they gate
  promotion to PROD and project administration.

---

*Sources: docs.crownpeak.com/firstspirit/user-management (Keycloak realms &
isolation, hosts/URLs, username=email, activation, group model + mapping/case
sensitivity, default groups, User-Manager/password-user rules, group/user
create-delete rules, federations, OIDC/SAML IdP setup, MFA-via-own-IdP);
docs.crownpeak.com/firstspirit/cloud-vs-self-hosted/cloud-specific-processes
(Project-Admin-only, no Server Admin). Verified against the User Management doc
2026-07-31; version-dependent — see the skill's review log.*
