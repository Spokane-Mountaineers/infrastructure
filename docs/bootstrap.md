# Bootstrap

One-time setup an operator runs before the first `tofu init` against a new environment. These steps create resources that OpenTofu itself depends on (state backend, identity), so they cannot be managed by OpenTofu — chicken-and-egg.

## 1. Enter the dev shell

All required tooling (`tofu`, `gcloud`, `az`) is declared in `flake.nix`. You need [Nix](https://determinate.systems/nix-installer/) with flakes enabled.

```bash
nix develop
```

That drops you into a shell with `opentofu`, `google-cloud-sdk`, and `azure-cli` on `$PATH` at the versions pinned in `flake.lock`. Verify:

```bash
tofu --version    # expect: OpenTofu v1.11.6
gcloud --version
az --version
```

If you use [direnv](https://direnv.net/) with [nix-direnv](https://github.com/nix-community/nix-direnv), add a `.envrc` containing `use flake` and the shell activates automatically on `cd`.

> `.opentofu-version` documents the pinned version for reference and CI runners not using the dev shell.

## 2. Create the GCS state bucket (one-time)

State for every environment in this repo lives in a single GCS bucket, keyed by environment + feature.

Choose:
- **GCP project**: `terraform-471204` (use an existing Spokane Mountaineers project, or create one).
- **Bucket name**: `spokane-mountaineers-tfstate` (must be globally unique).
- **Location**: `US-WEST1` (cheap regional, close to the org).

```bash
PROJECT=terraform-471204
BUCKET=spokane-mountaineers-tfstate

gcloud auth login
gcloud config set project "$PROJECT"

gcloud storage buckets create "gs://$BUCKET" \
  --project="$PROJECT" \
  --location=US-WEST1 \
  --uniform-bucket-level-access \
  --public-access-prevention

# Object versioning lets us recover a prior state file if something goes wrong.
gcloud storage buckets update "gs://$BUCKET" --versioning
```

Grant operators the `roles/storage.objectAdmin` role on the bucket so they can read and write state:

```bash
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" \
  --member="group:webdev@spokanemountaineers.org" \
  --role="roles/storage.objectAdmin"
```

Repeat the IAM binding for each operator who needs apply rights.

## 3. Operator authentication

Each operator does this once on their workstation. OpenTofu picks up both credentials automatically.

```bash
# GCS state backend reads Application Default Credentials.
gcloud auth application-default login

# azuread provider reads Azure CLI credentials.
az login
az account show          # verify you're in the expected tenant
```

## 4. Verify

Pick any environment directory and run `tofu init`:

```bash
cd terraform/environments/staging
tofu init
```

`tofu init` should report:
- Initializing the backend (gcs)…
- Initializing provider plugins…
- OpenTofu has been successfully initialized!

If `tofu init` fails on the backend step, re-check that:
- The bucket name in `backend.tf` matches the bucket created in step 2.
- Your gcloud ADC identity has `roles/storage.objectAdmin` on the bucket.
- `gcloud config get-value project` returns the project that owns the bucket.

If it fails on the `azuread` provider, re-run `az login` and `az account show` to confirm the active tenant.
