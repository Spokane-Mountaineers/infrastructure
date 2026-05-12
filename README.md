# Spokane Mountaineers — Infrastructure

OpenTofu-managed infrastructure for the Spokane Mountaineers organization. State lives in Google Cloud Storage; resources currently live in Microsoft Entra (Azure AD).

## Layout

```
.
├── .opentofu-version            # documents the pinned OpenTofu version for CI
├── flake.nix                    # Nix dev shell: opentofu, gcloud, azure-cli
├── docs/
│   └── bootstrap.md             # one-time GCS state-backend + auth setup
├── plans/                       # design docs for non-trivial infra changes
└── terraform/
    ├── modules/                 # reusable building blocks
    │   └── salesforce-oidc-app/ # Microsoft Entra App Registration for Salesforce sign-in
    └── stacks/
        ├── staging/             # staging Salesforce org integrations
        ├── production/          # production Salesforce org integrations
        └── azure-billing/       # Azure subscription budget alerts
```

## Tooling

All tooling is provided by the Nix dev shell declared in `flake.nix`. Run `nix develop` to enter it.

- **OpenTofu 1.11.6** — pinned via `flake.lock`. Expected upstream commit hash: `698e5e5204756963ffb28107fb61d77970e47f66`.
- **Azure CLI** (`az`) — operator authentication to Microsoft Entra (`az login`).
- **gcloud CLI** — operator authentication to GCS for state (`gcloud auth application-default login`).

## Quickstart

After completing the one-time bootstrap (see `docs/bootstrap.md`):

```bash
nix develop
cd terraform/stacks/staging
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

## Conventions

- Each stack under `terraform/stacks/` is a standalone OpenTofu root module with its own state file.
- Modules under `terraform/modules/` are reusable; stacks compose them.
- `*.tfvars` files contain environment-specific values and are gitignored. Each environment ships a `terraform.tfvars.example`.
- Significant changes ship with a planning doc under `plans/`.

## Plans

- [`plans/sign-in-with-microsoft.md`](plans/sign-in-with-microsoft.md) — Microsoft Entra App Registrations powering Sign in with Microsoft on the Spokane Mountaineers Experience Cloud sites.
