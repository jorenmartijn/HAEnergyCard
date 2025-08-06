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
  
  # Extract the hostname or IP from the URL
  HOSTNAME=$(echo "$API_URL" | sed -e 's|^[^/]*//||' -e 's|[:/].*$||')
  echo "Testing basic network connectivity to $HOSTNAME..."
  ping -c 3 "$HOSTNAME"
  
  echo "Testing power data endpoint..."
  curl -k -v "${API_URL}/api/energy/data/power/${TODAY}" 2>&1 | grep "< HTTP" || echo "No HTTP response received"
  
  echo "Testing gas data endpoint with sample response..."
  curl -k -s "${API_URL}/api/energy/data/gas/${TODAY}" | head -c 300
  echo "..."
  
  echo "Testing summary endpoint..."
  curl -k -s "${API_URL}/api/energy/summary/${TODAY}" | head -c 300
  echo "..."
  
  echo ""
  echo "Connectivity Troubleshooting Tips:"
  echo "=================================="
  echo "1. Make sure the server is running and accessible on the network"
  echo "2. Check for firewalls blocking access between devices"
  echo "3. Verify the correct port is included in the URL (e.g., :83)"
  echo "4. For HTTPS URLs, ensure SSL certificates are properly configured"
  echo "5. Try accessing the API directly from a web browser on the same device"
  echo "6. Check that the API server allows cross-origin requests (CORS)"
  echo ""
  
  # Add option to modify config for Home Assistant
  read -p "Would you like to add instructions for configuring Home Assistant? (y/n): " SHOW_HA_CONFIG
  if [ "$SHOW_HA_CONFIG" == "y" ]; then
    echo ""
    echo "Home Assistant Configuration:"
    echo "============================"
    echo "Add the card to your dashboard with this configuration:"
    echo ""
    echo "type: 'custom:energy-prices-card'"
    echo "api_url: '$API_URL'  # Make sure to include the port if needed"
    echo "title: 'Energy Prices'"
    echo "default_type: 'power'"
    echo ""
    echo "If the card still cannot connect, try using IP address instead of hostname"
    echo "or check if Home Assistant needs to be on the same network as the API."
    echo ""
  fi
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
