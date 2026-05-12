env_dir := "terraform/stacks"

# List available recipes
default:
    just --list

# Run tofu init for an environment
init env:
    tofu -chdir={{env_dir}}/{{env}} init

# Show a plan for an environment
plan env:
    tofu -chdir={{env_dir}}/{{env}} plan \
        $([ -f "{{env_dir}}/{{env}}/terraform.tfvars" ] && echo "-var-file=terraform.tfvars")

# Apply changes for an environment
apply env:
    tofu -chdir={{env_dir}}/{{env}} apply \
        $([ -f "{{env_dir}}/{{env}}/terraform.tfvars" ] && echo "-var-file=terraform.tfvars")

# Print a specific output value for an environment
output env key:
    tofu -chdir={{env_dir}}/{{env}} output -raw {{key}}

# Validate configuration for an environment
validate env:
    tofu -chdir={{env_dir}}/{{env}} validate

# Check formatting across all Terraform files
fmt:
    tofu fmt -check -recursive terraform/
