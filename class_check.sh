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

# Install required tools
if ! command -v clang-format &> /dev/null; then
  echo "clang-format could not be found, installing it..."
  sudo apt-get update
  sudo apt-get install -y clang-format cppcheck doxygen
fi

# Get the list of modified .cpp and .h files in the PR
pr_files=$(git diff --name-only origin/main...HEAD -- '*.cpp' '*.h')

if [ -z "$pr_files" ]; then
  echo "No relevant .cpp or .h files to check in PR #$PR_NUMBER."
  exit 0
fi

# Run cppcheck (static analysis) on the files
echo "Running static analysis (cppcheck)..."
cppcheck --enable=all --inconclusive --quiet --force $pr_files

# Check for missing class documentation
echo "Checking for missing class documentation..."
missing_docs=()

for file in $pr_files; do
  if [[ $file == *.cpp || $file == *.h ]]; then
    # Find all classes in the file
    classes=$(grep -n 'class ' "$file")
    while IFS= read -r class; do
      class_line=$(echo $class | cut -d: -f1)

      # Get the previous line and check if it is a Doxygen comment
      prev_line=$(($class_line - 1))
      prev_line_content=$(sed -n "${prev_line}p" "$file")

      # Check if the previous line is not a Doxygen comment (missing doc)
      if [[ ! "$prev_line_content" =~ ^\s*\/\*\* ]]; then
        missing_docs+=("$file:$class_line")
      fi
    done <<< "$classes"
  fi
done

if [ ${#missing_docs[@]} -gt 0 ]; then
  echo "The following classes are missing class documentation (please add a Doxygen comment explaining what the class does):"
  for doc in "${missing_docs[@]}"; do
    file=$(echo $doc | cut -d: -f1)
    line=$(echo $doc | cut -d: -f2)

    echo "  File: $file, Line: $line"
    echo "  Action: Please add a Doxygen comment above this class explaining its purpose and functionality."
    echo "  Example:"
    echo "    /**"
    echo "     * @brief Class description: What this class does."
    echo "     * @details More detailed explanation if needed."
    echo "     */"
    echo
  done
  exit 1
else
  echo "All classes are properly documented."
fi

echo "LLVM CLASS CHECK COMPLETE"
