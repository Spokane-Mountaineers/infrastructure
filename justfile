env_dir := "terraform/stacks"

# Nix sets TMPDIR to a deeply-nested path that exceeds macOS's 104-char Unix
# socket limit, causing go-plugin providers (e.g. azurerm 4.x) to fail on bind.
export TMPDIR := "/tmp"

# List available recipes
default:
    @just --list

# Print a formatted log line. Levels: INFO WARN ERROR OK
# Padding is outside the brackets so the message column is always aligned:
#   [INFO]  msg
#   [WARN]  msg
#   [ERROR] msg
#   [OK]    msg
_log level msg:
    #!/usr/bin/env sh
    case "{{level}}" in
        INFO)  label="[INFO] " ;;
        WARN)  label="[WARN] " ;;
        ERROR) label="[ERROR]" ;;
        OK)    label="[OK]   " ;;
        *)     label="[{{level}}]" ;;
    esac
    if [ -t 1 ]; then
        case "{{level}}" in
            INFO)  color="\033[0;34m" ; reset="\033[0m" ;;
            WARN)  color="\033[0;33m" ; reset="\033[0m" ;;
            ERROR) color="\033[0;31m" ; reset="\033[0m" ;;
            OK)    color="\033[0;32m" ; reset="\033[0m" ;;
            *)     color=""           ; reset=""         ;;
        esac
    fi
    printf "${color}%s${reset} %s\n" "$label" "{{msg}}"

# Ensure GCP Application Default Credentials are active (used by GCS state backend)
_auth_gcloud:
    #!/usr/bin/env sh
    just _log INFO "Checking GCP credentials"
    if gcloud auth application-default print-access-token > /dev/null 2>&1; then
        just _log OK "GCP credentials valid"
    else
        just _log WARN "GCP token expired — re-authenticating"
        gcloud auth application-default login
        just _log OK "GCP authenticated"
    fi

# Ensure Azure CLI session is active (used by azuread and azurerm providers)
_auth_az:
    #!/usr/bin/env sh
    just _log INFO "Checking Azure credentials"
    if az account show > /dev/null 2>&1; then
        just _log OK "Azure credentials valid"
    else
        just _log WARN "Azure session expired — re-authenticating"
        az login
        just _log OK "Azure authenticated"
    fi

# Run tofu init for a stack
init env: _auth_gcloud _auth_az
    @just _log INFO "Initializing {{env}}"
    @tofu -chdir={{env_dir}}/{{env}} init
    @just _log OK "{{env}} initialized"

# Show a plan for a stack
plan env: _auth_gcloud _auth_az
    @just _log INFO "Planning {{env}}"
    @tofu -chdir={{env_dir}}/{{env}} plan \
        $([ -f "{{env_dir}}/{{env}}/terraform.tfvars" ] && echo "-var-file=terraform.tfvars")

# Apply changes for a stack
apply env: _auth_gcloud _auth_az
    @just _log INFO "Applying {{env}}"
    @tofu -chdir={{env_dir}}/{{env}} apply \
        $([ -f "{{env_dir}}/{{env}}/terraform.tfvars" ] && echo "-var-file=terraform.tfvars")

# Print a specific output value for a stack
output env key: _auth_gcloud _auth_az
    @tofu -chdir={{env_dir}}/{{env}} output -raw {{key}}

# Validate configuration for a stack
validate env: _auth_gcloud _auth_az
    @just _log INFO "Validating {{env}}"
    @tofu -chdir={{env_dir}}/{{env}} validate

# Force-unlock a stuck state lock (use the lock ID shown in the error)
force-unlock env lock_id: _auth_gcloud
    @just _log WARN "Force-unlocking {{env}} (lock: {{lock_id}})"
    @tofu -chdir={{env_dir}}/{{env}} force-unlock -force {{lock_id}}

# Check formatting across all Terraform files
fmt:
    @just _log INFO "Checking Terraform formatting"
    @tofu fmt -check -recursive terraform/
