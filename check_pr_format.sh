#!/bin/bash

pr_number=$1
base_branch=${2:-main}

# Fetch the PR diff and list modified files (as done in Step 2)
response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/llvm/llvm-project/pulls/$pr_number/files")

# Check if response is empty or error occurred
if [[ -z "$response" || $(echo "$response" | jq '.message') == *"Not Found"* ]]; then
    echo -e "❌ Failed to fetch PR diff or invalid PR number."
    exit 1
fi

# Extract modified files
modified_files=$(echo "$response" | jq -r '.[].filename')

# Fetch the PR locally
git fetch origin pull/$pr_number/head:pr-$pr_number || { echo "❌ Failed to fetch PR"; exit 1; }

# Checkout to the PR branch
git checkout pr-$pr_number

# Loop through each modified file
for file in $modified_files; do
    echo -e "📂 Checking formatting for file: $file"
    
    # Run git-clang-format on the file to check formatting issues
    clang_output=$(git clang-format $base_branch --diff -- $file)
    
    if [ -n "$clang_output" ] && ! echo "$clang_output" | grep -q "no modified files to format"; then
        echo -e "🚨 Format issues detected in $file:"
        echo "$clang_output"  # Display diff with formatting issues
    else
        echo -e "✅ No formatting issues in $file."
    fi
done
