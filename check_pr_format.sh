#!/bin/bash

# Usage: ./check_pr_format.sh <pr_number> [base_branch]
# Example: ./check_pr_format.sh 123 main

pr_number=$1
base_branch=${2:-main}

# Check if PR number is provided
if [ -z "$pr_number" ]; then
    echo -e "\033[1;31m❌ Usage: $0 <pr_number> [base_branch]\033[0m"
    exit 1
fi

pr_branch="pr-$pr_number"

echo -e "\033[1;34m📥 Fetching PR #$pr_number...\033[0m"
git fetch origin pull/$pr_number/head:$pr_branch || { echo -e "\033[1;31m❌ Failed to fetch PR\033[0m"; exit 1; }

# Define extensions to check
extensions="c|cpp|cc|cxx|java|js|json|m|h|proto|cs"

echo -e "\033[1;36m🔍 Finding files modified between $base_branch and $pr_branch...\033[0m"
modified_files=$(git diff --name-only $base_branch $pr_branch | grep -E "\.(${extensions})$")

if [ -z "$modified_files" ]; then
    echo -e "\033[1;32m✅ No relevant files modified in this PR.\033[0m"
    exit 0
fi

echo -e "\033[1;33m📂 Modified files:\033[0m"
echo "$modified_files"

# Checkout to the PR branch
git checkout $pr_branch >/dev/null

echo -e "\033[1;35m🧼 Checking formatting issues with clang-format...\033[0m"
clang_output=$(git clang-format $base_branch --diff -- $modified_files)

if [ -n "$clang_output" ] && ! echo "$clang_output" | grep -q "no modified files to format"; then
    echo -e "\033[1;31m🚨 Format issues detected:\033[0m"
    echo -e "\033[1;37m--------------------------------------\033[0m"

    # Extract original unformatted code from diff (lines starting with "---")
    echo -e "\033[1;31mOriginal Code (Unformatted):\033[0m"
    
    echo "$clang_output" | grep -E "^\- " | cut -d ' ' -f 2- 

    # Extract formatted code from diff (lines starting with "+")
    echo -e "\033[1;32m--------------------------------------\033[0m"
    echo -e "\033[1;32mFormatted Code (After git clang-format):\033[0m"
    
    echo "$clang_output" | grep -E "^\+ " | cut -d ' ' -f 2-

    echo -e "\033[1;37m--------------------------------------\033[0m"
    echo -e "\033[1;33m💡 Suggested Fix:\033[0m"
    echo -e "   \033[1;32mgit clang-format $base_branch\033[0m"
    echo -e "\033[1;34m📘 This will auto-fix the formatting for the changed lines.\033[0m"
    exit 1
else
    echo -e "\033[1;32m✅ No formatting issues detected!\033[0m"
    exit 0
fi
