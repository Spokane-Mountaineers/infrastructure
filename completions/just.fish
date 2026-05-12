# List stack directories under terraform/stacks/
function __just_list_envs
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    or return
    for d in $root/terraform/stacks/*/
        basename $d
    end
end

# List output names for a given stack by parsing its outputs.tf
function __just_list_outputs
    set -l env $argv[1]
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    or return
    set -l f $root/terraform/stacks/$env/outputs.tf
    test -f $f || return
    grep '^output "' $f | string replace -r '^output "([^"]+)".*' '$1'
end

# True when no recipe has been given yet
function __just_at_recipe
    not __fish_seen_subcommand_from init plan apply output validate fmt
end

# True when the cursor is at the env argument (position 3, i.e. count of prior tokens = 2)
function __just_at_env_arg
    __fish_seen_subcommand_from init plan apply validate output
    and test (count (commandline -opc)) -eq 2
end

# True when the cursor is at the key argument of `output` (position 4)
function __just_at_output_key
    __fish_seen_subcommand_from output
    and test (count (commandline -opc)) -eq 3
end

# Recipe names
complete -c just -f -n __just_at_recipe -a init     -d 'Run tofu init for an environment'
complete -c just -f -n __just_at_recipe -a plan     -d 'Show a plan for an environment'
complete -c just -f -n __just_at_recipe -a apply    -d 'Apply changes for an environment'
complete -c just -f -n __just_at_recipe -a output   -d 'Print a specific output value'
complete -c just -f -n __just_at_recipe -a validate -d 'Validate configuration for an environment'
complete -c just -f -n __just_at_recipe -a fmt      -d 'Check formatting across all Terraform files'

# Environment argument (first positional arg for all env-scoped recipes)
complete -c just -f -n __just_at_env_arg -a '(__just_list_envs)'

# Output key argument (second positional arg for `output`, derived from the env's outputs.tf)
complete -c just -f -n __just_at_output_key -a '(__just_list_outputs (commandline -opc)[3])'
