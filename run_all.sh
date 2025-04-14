#!/bin/bash
CONFIG="scripts_config.yaml"
PR_NUMBER="$1"

run_if_enabled() {
  local key=$1
  local script=$2
  local needs_pr=$3

  config_value=$(yq e ".$key" "$CONFIG")
  echo "Config value for $key: $config_value"

  if [[ "$config_value" == "true" ]]; then
    echo "✅ Running $script"
    if [ "$needs_pr" = true ]; then
      bash "$script" "$PR_NUMBER"
    else
      bash "$script"
    fi
  else
    echo "❌ Skipping $script"
  fi
}

# List of all checks
declare -A checks=(
  ["check_pr_format"]="check_pr_format.sh true"
  ["class_check"]="class_check.sh false"
  ["llvmheader"]="llvmheader.sh false"
  ["naming_conventions_check"]="naming_conventions_check.sh false"
)

# Loop through all checks
for key in "${!checks[@]}"; do
  IFS=" " read -r script needs_pr <<< "${checks[$key]}"
  run_if_enabled "$key" "$script" "$needs_pr"
done
