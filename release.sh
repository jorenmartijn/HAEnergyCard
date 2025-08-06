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

# Check API connectivity if user wants to
read -p "Do you want to test API connectivity? (y/n): " TEST_API
if [ "$TEST_API" == "y" ]; then
  read -p "Enter API URL (e.g., https://100.107.164.25:83): " API_URL
  
  echo "Testing API connectivity..."
  # Get today's date in YYYY-MM-DD format
  TODAY=$(date +%Y-%m-%d)
  
  echo "Testing power data endpoint..."
  curl -k -s -o /dev/null -w "Power data endpoint: %{http_code}\n" "${API_URL}/api/energy/data/power/${TODAY}"
  
  echo "Testing gas data endpoint..."
  curl -k -s -o /dev/null -w "Gas data endpoint: %{http_code}\n" "${API_URL}/api/energy/data/gas/${TODAY}"
  
  echo "Testing summary endpoint..."
  curl -k -s -o /dev/null -w "Summary endpoint: %{http_code}\n" "${API_URL}/api/energy/summary/${TODAY}"
  
  echo ""
  echo "If you see '200' responses, your API is accessible."
  echo "If you see '000' responses, there might be connectivity issues."
  echo "Other error codes indicate specific API issues."
  echo ""
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
