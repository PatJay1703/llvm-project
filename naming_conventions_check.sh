#!/bin/bash

# Check if a PR number is provided
if [ -z "$1" ]; then
  echo "Please provide a pull request number as an argument."
  exit 1
fi

PR_NUMBER=$1

# Fetch the latest changes and check out the PR branch
echo "Fetching changes for PR #$PR_NUMBER"
git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER

# Checkout to the PR branch
git checkout pr-$PR_NUMBER

# Install clang if not installed
if ! command -v clang &> /dev/null; then
  echo "clang could not be found, installing it..."
  sudo apt-get update
  sudo apt-get install -y clang
fi

# Get the list of modified .cpp and .h files in the PR
pr_files=$(git diff --name-only origin/main...HEAD -- '*.cpp' '*.h')

if [ -z "$pr_files" ]; then
  echo "No relevant .cpp or .h files to check in PR #$PR_NUMBER."
  exit 0
fi

# Check for naming convention violations
for file in $pr_files; do
  if [[ $file == *.cpp || $file == *.h ]]; then
    echo "Checking naming conventions in file: $file"

    # Check class names (should start with an uppercase letter and be a noun)
    class_errors=$(grep -E -n 'class [a-z]' "$file")
    if [ ! -z "$class_errors" ]; then
      echo "Violation: Class names should start with an uppercase letter."
      echo "Example fix:"
      echo "  Wrong: class textFileReader"
      echo "  Correct: class TextFileReader"
      echo "Line(s) with violation(s):"
      echo "$class_errors"
    fi

    # Check variable names (should be camelCase, start with an uppercase letter, and be a noun)
    var_errors=$(grep -E -n '\b[A-Za-z][a-zA-Z0-9_]*\b' "$file" | grep -v '^[a-z]')
    if [ ! -z "$var_errors" ]; then
      echo "Violation: Variable names should start with a lowercase letter, be camelCase, and be nouns."
      echo "Example fix:"
      echo "  Wrong: int Leader"
      echo "  Correct: int leader"
      echo "Line(s) with violation(s):"
      echo "$var_errors"
    fi

    # Check function names (should be verb phrases, camelCase, and start with a lowercase letter)
    func_errors=$(grep -E -n 'void [A-Z]' "$file")
    if [ ! -z "$func_errors" ]; then
      echo "Violation: Function names should start with a lowercase letter, be camelCase, and represent actions."
      echo "Example fix:"
      echo "  Wrong: void OpenFile()"
      echo "  Correct: void openFile()"
      echo "Line(s) with violation(s):"
      echo "$func_errors"
    fi

    # Check enum declarations (should start with an uppercase letter and follow the type naming convention)
    enum_errors=$(grep -E -n 'enum [a-z]' "$file")
    if [ ! -z "$enum_errors" ]; then
      echo "Violation: Enum declarations should start with an uppercase letter."
      echo "Example fix:"
      echo "  Wrong: enum valueKind"
      echo "  Correct: enum ValueKind"
      echo "Line(s) with violation(s):"
      echo "$enum_errors"
    fi

    # Check enum values for 'Kind' suffix (for discriminators)
    enum_kind_errors=$(grep -E -n 'enum' "$file" | grep -v 'Kind$')
    if [ ! -z "$enum_kind_errors" ]; then
      echo "Violation: Enum values used as discriminators should have the 'Kind' suffix."
      echo "Example fix:"
      echo "  Wrong: enum Value"
      echo "  Correct: enum ValueKind"
      echo "Line(s) with violation(s):"
      echo "$enum_kind_errors"
    fi

  fi
done

echo "Naming convention checks complete."
