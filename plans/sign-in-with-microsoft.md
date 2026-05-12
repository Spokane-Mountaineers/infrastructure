# Sign in with Microsoft — Infrastructure Plan

## Context

Members of the Spokane Mountaineers Experience Cloud site already have a "Sign in with Google" button. We are adding a parallel "Sign in with Microsoft" flow on top of the Microsoft Identity Platform (OpenID Connect / OAuth 2.0 v2.0). The Salesforce-side work — Apex registration handler, Visualforce login page, member-facing docs — happens in the [`Spokane-Mountaineers/salesforce`](https://github.com/Spokane-Mountaineers/salesforce) repo.

The Azure side — the Microsoft Entra App Registrations that issue tokens to Salesforce — lives here. This is the first feature the infrastructure repo manages, so this plan also bootstraps the repo's conventions: directory layout, state backend, operator authentication, version pinning.

## Decisions

| Choice | Value |
|---|---|
| IaC tool | OpenTofu **1.11.6** (upstream commit `698e5e5204756963ffb28107fb61d77970e47f66`); version pinned via `flake.lock`; `.opentofu-version` retained for CI reference |
| State backend | Google Cloud Storage (`backend "gcs"`), bucket `spokane-mountaineers-tfstate`, object versioning enabled |
| Azure auth | Azure CLI (`az login`) — operator identity for v1; CI federation later |
| GCS auth | gcloud Application Default Credentials (`gcloud auth application-default login`) |
| Tenant audience | `AzureADandPersonalMicrosoftAccount` (matches the `/common` authority) |
| Topology | Two App Registrations — one per Salesforce environment (`staging`, `production`) |
| Provider versions | `hashicorp/azuread ~> 3.0`, `hashicorp/time ~> 0.9` |

## Files in this repo (after this change)

```
.
├── README.md
├── .opentofu-version                                 # 1.11.6 (for CI reference)
├── .gitignore
├── flake.nix                                         # Nix dev shell: opentofu, gcloud, azure-cli
├── flake.lock                                        # pins nixpkgs revision
├── docs/
│   └── bootstrap.md                                  # one-time GCS + auth setup
├── plans/
│   └── sign-in-with-microsoft.md                     # THIS DOC
└── terraform/
    ├── modules/
    │   └── salesforce-oidc-app/
    │       ├── main.tf                               # azuread_application + service_principal + password
    │       ├── variables.tf                          # display_name, redirect_uris, client_secret_lifetime_hours
    │       ├── outputs.tf                            # client_id, client_secret (sensitive), tenant_id, object_id
    │       └── versions.tf                           # OpenTofu 1.11.6, azuread ~> 3.0
    └── stacks/
        ├── staging/
        │   ├── backend.tf                            # gcs, key=sign-in-with-microsoft/staging
        │   ├── providers.tf                          # provider "azuread" {}
        │   ├── main.tf                               # calls salesforce-oidc-app module
        │   ├── variables.tf                          # salesforce_callback_url
        │   ├── outputs.tf                            # re-exports module outputs
        │   ├── versions.tf
        │   └── terraform.tfvars.example              # placeholder callback URL
        └── production/                               # mirrors staging/
            └── …
```

## The module: `terraform/modules/salesforce-oidc-app/`

Reusable wrapper around an Entra App Registration intended for Salesforce OpenID Connect Auth Providers. Resources:

- `azuread_application.this` — display name, `sign_in_audience = "AzureADandPersonalMicrosoftAccount"`, `web.redirect_uris`, `web.implicit_grant` disabled (auth-code flow), Microsoft Graph delegated permissions for `openid`, `profile`, `email`, `User.Read`, optional `email` claim added to ID and access tokens.
- `azuread_service_principal.this` — required for the app to be usable in the home tenant.
- `time_rotating.client_secret` — drives secret expiry; when the rotation period elapses the next plan recreates the password automatically.
- `azuread_application_password.this` — client secret; `end_date` is set to `time_rotating.client_secret.rotation_rfc3339`.

Inputs: `display_name`, `redirect_uris` (list, validated non-empty), `client_secret_rotation_days` (default 365).
Outputs: `client_id`, `client_secret` (sensitive), `tenant_id`, `object_id`.

## Apply order (handles the Salesforce ↔ Azure circular dependency)

The Salesforce Auth Provider can't be created until the Entra app exists, and the Entra app's redirect URI can't be set until Salesforce has generated its callback URL. Resolution: two passes.

1. **First apply** with a placeholder `salesforce_callback_url` (e.g. `https://placeholder.invalid/...`). Captures `client_id` and `client_secret`.
2. **Salesforce side** — operator creates the Salesforce Auth Provider in Setup using those values. Salesforce generates the real callback URL.
3. **Second apply** with the real callback URL pasted into `terraform.tfvars`. The redirect URI updates in place.

## Verification

1. **Format / validate**:
   ```bash
   tofu fmt -check -recursive
   cd terraform/stacks/staging && tofu init && tofu validate
   ```
2. **Plan should show**: 1 `azuread_application`, 1 `azuread_service_principal`, 1 `time_rotating`, 1 `azuread_application_password` (no other resources).
3. **First apply** (placeholder URL):
   ```bash
   tofu apply -var-file=terraform.tfvars
   tofu output -raw client_id
   tofu output -raw client_secret      # sensitive — do not commit
   ```
4. **Sanity check in Azure**:
   ```bash
   az ad app show --id "$(tofu output -raw client_id)" \
     --query "{name:displayName, audience:signInAudience, redirects:web.redirectUris}"
   ```
5. **Second apply** after Salesforce gives back the real callback URL: edit `terraform.tfvars`, run `tofu apply`, confirm the redirect URI is updated.
6. **End-to-end** validation happens in the SMI repo (Apex tests) and in the Salesforce community (manual sign-in with various Microsoft account types).

## Out of scope

- Production rollout — runs the `production/` environment after staging is verified.
- GitHub Actions CI for `tofu plan`/`apply` — comes after the local-apply flow is proven; will use OIDC federation rather than a long-lived secret.
- Any Salesforce-side changes (handled in `Spokane-Mountaineers/salesforce`).

## Cross-repo references

- Salesforce side: `Spokane-Mountaineers/salesforce` → `force-app/main/default/classes/MicrosoftAuthRegistrationHandler.cls`, `force-app/main/default/pages/CommunitiesLogin.page`, `docs/automation/microsoft-login-automation.md`.
- This module's outputs feed Salesforce Auth Provider fields:
  - `client_id` → Consumer Key
  - `client_secret` → Consumer Secret
  - Tenant audience drives the authorize/token endpoints, fixed at `https://login.microsoftonline.com/common/oauth2/v2.0/{authorize,token}` on the Salesforce side.
