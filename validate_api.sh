#!/bin/bash

# API Validation Script for Energy Prices Card
echo "Energy API Validation Script"
echo "==========================="

# Get API URL from user
read -p "Enter API URL (e.g., https://100.107.164.25:83): " API_URL

# Get today's date
TODAY=$(date +%Y-%m-%d)
echo "Testing with today's date: $TODAY"

# Function to validate API response against expected schema
validate_response() {
  local url=$1
  local description=$2
  local expected_fields=$3
  
  echo ""
  echo "Testing $description..."
  echo "URL: $url"
  
  # Get response
  RESPONSE=$(curl -s -k "$url")
  STATUS=$?
  
  if [ $STATUS -ne 0 ]; then
    echo "ERROR: Failed to connect to API"
    return 1
  fi
  
  echo "Response received:"
  echo "$RESPONSE" | head -c 300
  echo "..."
  
  # Check if it's valid JSON
  if ! echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    echo "ERROR: Response is not valid JSON"
    return 1
  fi
  
  # Check for expected fields
  for field in $expected_fields; do
    if ! echo "$RESPONSE" | jq ".$field" > /dev/null 2>&1; then
      echo "ERROR: Response missing expected field '$field'"
    else
      echo "OK: Found expected field '$field'"
    fi
  done
  
  return 0
}

# Test the power data endpoint
validate_response "${API_URL}/api/energy/data/power/${TODAY}" "Power data endpoint" "type date data"

# Check data.Prices structure in power data
POWER_PRICES=$(curl -s -k "${API_URL}/api/energy/data/power/${TODAY}" | jq -r '.data.Prices | length')
if [ "$POWER_PRICES" != "null" ] && [ "$POWER_PRICES" -gt 0 ]; then
  echo "OK: Found data.Prices array with $POWER_PRICES entries"
else
  echo "ERROR: Missing or empty data.Prices array"
fi

# Test the gas data endpoint
validate_response "${API_URL}/api/energy/data/gas/${TODAY}" "Gas data endpoint" "type date data"

# Test the summary endpoint
validate_response "${API_URL}/api/energy/summary/${TODAY}" "Summary endpoint" "power gas"

echo ""
echo "Testing Complete"
echo "================"
echo ""
echo "If all tests passed, your API should work correctly with the Energy Prices card."
echo "If any tests failed, you may need to modify the card to match your API response format."
echo ""
echo "API URL configuration for your card should be:"
echo ""
echo "type: 'custom:energy-prices-card'"
echo "api_url: '$API_URL'  # Make sure to include the port if needed"
echo "title: 'Energy Prices'"
echo "default_type: 'power'"
