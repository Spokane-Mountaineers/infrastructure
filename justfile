env_dir := "terraform/stacks"

# List available recipes
default:
    just --list

# Ensure GCP Application Default Credentials are active (used by GCS state backend)
_auth_gcloud:
    gcloud auth application-default print-access-token > /dev/null 2>&1 || gcloud auth application-default login

# Ensure Azure CLI session is active (used by azuread and azurerm providers)
_auth_az:
    az account show > /dev/null 2>&1 || az login

# Run tofu init for a stack
init env: _auth_gcloud _auth_az
    tofu -chdir={{env_dir}}/{{env}} init

# Show a plan for a stack
plan env: _auth_gcloud _auth_az
    tofu -chdir={{env_dir}}/{{env}} plan \
        $([ -f "{{env_dir}}/{{env}}/terraform.tfvars" ] && echo "-var-file=terraform.tfvars")

# Apply changes for a stack
apply env: _auth_gcloud _auth_az
    tofu -chdir={{env_dir}}/{{env}} apply \
        $([ -f "{{env_dir}}/{{env}}/terraform.tfvars" ] && echo "-var-file=terraform.tfvars")

# Print a specific output value for a stack
output env key: _auth_gcloud _auth_az
    tofu -chdir={{env_dir}}/{{env}} output -raw {{key}}

# Validate configuration for a stack
validate env: _auth_gcloud _auth_az
    tofu -chdir={{env_dir}}/{{env}} validate

# Check formatting across all Terraform files
fmt:
    tofu fmt -check -recursive terraform/
