#!/bin/bash

# Release script for Energy Prices Card

# Get current version from package.json
CURRENT_VERSION=$(grep -o '"version": "[^"]*' package.json | cut -d'"' -f4)

# Ask for new version
echo "Current version is $CURRENT_VERSION"
read -p "Enter new version (leave empty to keep current): " NEW_VERSION

# If new version is provided, update package.json
if [ ! -z "$NEW_VERSION" ]; then
  sed -i "s/\"version\": \"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" package.json
  echo "Updated version to $NEW_VERSION"
else
  NEW_VERSION=$CURRENT_VERSION
  echo "Keeping version $NEW_VERSION"
fi

# Make sure energy-prices-card.js is in the root directory
if [ -f "dist/energy-prices-card.js" ]; then
  cp dist/energy-prices-card.js ./energy-prices-card.js
  echo "Copied energy-prices-card.js to root directory"
fi

# Create a git tag
echo "Creating git tag v$NEW_VERSION"
git add .
git commit -m "Release v$NEW_VERSION"
git tag "v$NEW_VERSION"

# Push to GitHub
echo "Ready to push to GitHub"
read -p "Push changes to GitHub? (y/n): " PUSH_CONFIRM

if [ "$PUSH_CONFIRM" == "y" ]; then
  git push origin main
  git push origin "v$NEW_VERSION"
  echo "Changes pushed to GitHub"
fi

echo "Release completed!"
