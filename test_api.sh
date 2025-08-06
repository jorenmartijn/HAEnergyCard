#!/bin/bash

# API Connectivity Test for Energy Prices Card
echo "Energy Prices API Connectivity Test"
echo "=================================="
echo ""

# Get API URL from command line or ask user
if [ -z "$1" ]; then
  read -p "Enter API URL (e.g., https://100.107.164.25:83): " API_URL
else
  API_URL=$1
fi

# Get today's date in YYYY-MM-DD format
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

echo "Testing with today's date: $TODAY"
echo "Testing with yesterday's date: $YESTERDAY"
echo ""

# Function to test endpoint and display response
test_endpoint() {
  local url=$1
  local description=$2
  
  echo "Testing $description..."
  echo "URL: $url"
  
  # First check status code
  STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$url")
  echo "Status code: $STATUS"
  
  # If status is 200, get and display a snippet of the response
  if [ "$STATUS" == "200" ]; then
    echo "Response snippet:"
    curl -k -s "$url" | head -c 300
    echo "..."
  fi
  echo ""
}

# Test all endpoints
test_endpoint "${API_URL}/api/energy/data/power/${TODAY}" "Power data (today)"
test_endpoint "${API_URL}/api/energy/data/power/${YESTERDAY}" "Power data (yesterday)" 
test_endpoint "${API_URL}/api/energy/data/gas/${TODAY}" "Gas data (today)"
test_endpoint "${API_URL}/api/energy/summary/${TODAY}" "Summary data (today)"

# Test direct IP access vs domain name if applicable
echo "Testing network connectivity..."
IP_ADDRESS=$(echo "$API_URL" | sed -E 's|https?://([^:/]+).*|\1|')
echo "IP address extracted: $IP_ADDRESS"
if [[ $IP_ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Testing ping to $IP_ADDRESS..."
  ping -c 3 $IP_ADDRESS
else
  echo "URL doesn't contain a direct IP address. Consider testing with IP instead of hostname."
fi

echo ""
echo "Connectivity Troubleshooting Tips:"
echo "=================================="
echo "1. If all status codes are '000', check if the server is running"
echo "2. If using HTTPS, make sure certificates are valid or use -k with curl"
echo "3. Check if the correct port is included in the URL (e.g., :83)"
echo "4. Verify that CORS is enabled on the server for browser access"
echo "5. If Home Assistant is in a Docker container, check network settings"
echo ""
echo "Home Assistant Card Configuration:"
echo "================================="
echo "Make sure your card configuration includes the correct API URL:"
echo ""
echo "type: 'custom:energy-prices-card'"
echo "api_url: '$API_URL'  # Include port if needed"
echo "title: 'Energy Prices'"
echo "default_type: 'power'"
