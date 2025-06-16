#!/bin/bash

# Script to recursively delete Zone.Identifier files while skipping node_modules folders

echo "Searching for Zone.Identifier files (excluding node_modules)..."

# Find and delete Zone.Identifier files, excluding node_modules directories
find . -name "*:Zone.Identifier" -not -path "*/node_modules/*" -type f -print -delete

echo "Cleanup complete!"

# Optional: Show count of remaining Zone.Identifier files
remaining=$(find . -name "*:Zone.Identifier" -not -path "*/node_modules/*" -type f | wc -l)
echo "Remaining Zone.Identifier files (excluding node_modules): $remaining"