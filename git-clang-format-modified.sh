#!/bin/bash

# Check if the user provided a file to format
if [ $# -lt 1 ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

FILE=$1

# Step 1: Get the diff of the modified lines in the file
MODIFIED_LINES=$(git diff --unified=0 -- $FILE | grep -E '^\+[^+]+' | sed 's/^+//')

if [ -z "$MODIFIED_LINES" ]; then
  echo "No modified lines found."
  exit 0
fi

# Step 2: Create a temporary file and insert modified lines
TEMP_FILE=$(mktemp)
echo "$MODIFIED_LINES" > $TEMP_FILE

# Step 3: Format the temporary file with clang-format
clang-format -i $TEMP_FILE

# Step 4: Replace modified lines back in the original file
# This assumes you're handling the modified lines manually after formatting them.

# This step would be more complex if you want to replace exact lines, but for now, you would
# need to manually inspect the diff, or use a diff/patch tool to merge the changes back.

# Step 5: Add the changes to staging area
git add $FILE

echo "Formatted modified lines and staged the changes."
