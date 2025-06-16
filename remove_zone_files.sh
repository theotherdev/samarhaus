#!/bin/bash

# --- Bash Script to Remove Zone Identifier Related Files ---
# This script helps identify and remove files that might contain
# "Zone Identifier" metadata, primarily targeting scenarios where
# this metadata might have been extracted into separate files
# on a non-NTFS filesystem (like Linux ext4, macOS HFS+, etc.).
#
# Zone Identifier information typically refers to Alternate Data Streams (ADS)
# on Windows NTFS filesystems (e.g., 'filename:Zone.Identifier').
# Standard Linux commands do not directly interact with NTFS ADS unless
# specific tools (like 'attr' with an 'ntfs-3g' mounted filesystem using
# 'user_xattr' option) are used.
#
# This script focuses on two main scenarios on non-NTFS filesystems:
# 1. Files explicitly named with 'Zone.Identifier' (e.g., 'document.pdf:Zone.Identifier').
# 2. Files whose content contains the typical '[ZoneTransfer]' header,
#    indicating they might be extracted Zone Identifier streams.
#
# USE WITH CAUTION: Always review the files before confirming deletion.

echo "--- Zone Identifier File Removal Script ---"
echo "Searching for files related to Zone Identifiers in the current directory and its subdirectories."
echo "This script looks for files:"
echo "  1. Whose names contain 'Zone.Identifier'."
echo "  2. Whose content contains '[ZoneTransfer]' (common in actual Zone Identifier streams)."
echo ""

# Ask for initial confirmation to proceed
read -p "Do you want to proceed with the search? (y/N): " confirm_search
if [[ ! "$confirm_search" =~ ^[yY](es)?$ ]]; then
    echo "Search cancelled."
    exit 0
fi

echo ""
echo "Finding files named like '*Zone.Identifier*'..."
# Find files where "Zone.Identifier" is part of the filename
# -type f: only regular files
# -print0: null-terminate output for safety with special characters in filenames
named_files=$(find . -type f -name "*Zone.Identifier*" -print0)
if [[ -n "$named_files" ]]; then
    echo "Found files with 'Zone.Identifier' in their name:"
    # Use xargs with -0 and -I {} to safely print each file
    echo "$named_files" | xargs -0 -I {} echo "  - {}"
else
    echo "No files found with 'Zone.Identifier' in their name."
fi
echo ""

echo "Finding files whose content contains '[ZoneTransfer]'..."
# Find files whose content contains the string '[ZoneTransfer]'
# -l: only print the filename
# -r: recursive search
# -I: ignore binary files
# --include and --exclude: refine search to avoid common problematic directories/file types
content_files=$(grep -rlI --include=\* --exclude=*.sh --exclude=*.log --exclude=.git\* --exclude=\*cache\* --exclude=\*node_modules\* '[ZoneTransfer]' .)
if [[ -n "$content_files" ]]; then
    echo "Found files with '[ZoneTransfer]' in their content:"
    # Loop through lines and print, handling potential spaces in filenames
    echo "$content_files" | while IFS= read -r line; do echo "  - $line"; done
else
    echo "No files found with '[ZoneTransfer]' in their content."
fi
echo ""

# Collect all unique files identified for removal
# Using a temporary file for robustness with null-terminated strings
temp_file=$(mktemp)
if [[ -n "$named_files" ]]; then
    echo "$named_files" | xargs -0 -I {} echo "{}" >> "$temp_file"
fi
if [[ -n "$content_files" ]]; then
    # Read content files line by line, add to temp_file if not already present
    echo "$content_files" | while IFS= read -r line; do
        # Check if the line (filename) is already in the temp_file (case-sensitive)
        # Using grep -qF to quickly check for fixed string in temp_file
        if ! grep -qF -- "$line" "$temp_file"; then
            echo "$line" >> "$temp_file"
        fi
    done
fi

# Convert the temporary file content back to null-separated string for xargs
# This ensures that `all_files_to_remove` is a single string with null terminators
# for safe processing by xargs -0.
all_files_to_remove=""
if [[ -s "$temp_file" ]]; then # Check if temp_file is not empty
    all_files_to_remove=$(cat "$temp_file" | tr '\n' '\0')
fi

# Clean up the temporary file
rm "$temp_file"

if [[ -z "$all_files_to_remove" ]]; then
    echo "No Zone Identifier related files found to remove."
    exit 0
fi

echo "--- Summary of files to be removed ---"
# Print the list of files to be removed
echo "$all_files_to_remove" | xargs -0 -I {} echo "  - {}"
echo ""

# Ask for final confirmation before deletion
read -p "Are you sure you want to PERMANENTLY remove the listed files? This action cannot be undone. (y/N): " confirm_delete
if [[ ! "$confirm_delete" =~ ^[yY](es)?$ ]]; then
    echo "Deletion cancelled. No files were removed."
    exit 0
fi

echo "Removing files..."
# Use xargs -0 with rm -v (verbose) to delete files safely
echo "$all_files_to_remove" | xargs -0 rm -v
echo "Removal complete."
echo "-------------------------------------"
