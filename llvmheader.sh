#!/bin/bash

# Usage: ./check_llvm_header_format.sh <pr_number> [base_branch]
# Example: ./check_llvm_header_format.sh 123 main

# Get input arguments
pr_number=$1
base_branch=${2:-main}

# Check if PR number is provided
if [ -z "$pr_number" ]; then
    echo "❌ Usage: $0 <pr_number> [base_branch]"
    exit 1
fi

# Create a local name for the PR branch
pr_branch="pr-$pr_number"

# Check if currently on the same branch we want to fetch into
current_branch=$(git symbolic-ref --short HEAD)
if [ "$current_branch" == "$pr_branch" ]; then
    echo "🔁 Currently on $pr_branch, switching to $base_branch to avoid fetch conflict..."
    git checkout $base_branch || { echo "❌ Failed to checkout $base_branch"; exit 1; }
fi

echo "📥 Fetching PR #$pr_number..."
git fetch origin pull/$pr_number/head:$pr_branch || { echo "❌ Failed to fetch PR"; exit 1; }

# Define extensions to check (includes header and source files)
extensions="c|cpp|cc|cxx|java|js|json|m|h|proto|cs"

echo "🔍 Finding files modified between $base_branch and $pr_branch..."
modified_files=$(git diff --name-only $base_branch $pr_branch | grep -E "\.(${extensions})$")

if [ -z "$modified_files" ]; then
    echo "✅ No relevant files modified in this PR."
    exit 0
fi

echo "📂 Modified files:"
echo "$modified_files"

# LLVM header template to check for
llvm_header_template="//===----------------------------------------------------------------------===//"
llvm_license="// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception"

# Function to check if header has LLVM-style comment block
check_header_format() {
    file=$1
    if ! grep -q "$llvm_header_template" "$file"; then
        echo ""
        echo "❌ Missing or incorrect LLVM-style header comment block in $file"
        echo "Expected format:"
        echo "$llvm_header_template"
        echo "$llvm_license"
        return 1
    fi
    return 0
}

# Iterate through modified files and check each one
missing_headers=0
for file in $modified_files; do
    if ! check_header_format "$file"; then
        missing_headers=$((missing_headers+1))
    fi
done

if [ $missing_headers -gt 0 ]; then
    echo "❌ $missing_headers file(s) missing proper LLVM-style comments."
    exit 1
else
    echo "✅ All modified files have the correct LLVM-style comments!"
    exit 0
fi
