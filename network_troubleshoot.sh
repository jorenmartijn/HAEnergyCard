#!/bin/bash

# Network connectivity troubleshooting script for Energy Prices Card
echo "Energy API Network Troubleshooter"
echo "================================"
echo ""

# Get API URL
read -p "Enter API URL (e.g., https://100.107.164.25:83): " API_URL

# Parse URL components
PROTOCOL=$(echo "$API_URL" | sed -e 's|^\([^/]*\)://.*|\1|')
HOSTNAME=$(echo "$API_URL" | sed -e 's|^[^/]*//||' -e 's|[:/].*$||')
PORT=$(echo "$API_URL" | sed -e 's|^.*:||' -e 's|/.*$||')

# Check if port is numeric, if not, assign default based on protocol
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  if [ "$PROTOCOL" == "https" ]; then
    PORT=443
  else
    PORT=80
  fi
fi

echo "Analyzing connection to:"
echo "Protocol: $PROTOCOL"
echo "Host: $HOSTNAME"
echo "Port: $PORT"
echo ""

# Function to display section header
section() {
  echo ""
  echo "=== $1 ==="
  echo ""
}

# Basic network connectivity test
section "Basic Connectivity"
echo "Testing if host is reachable..."
ping -c 3 "$HOSTNAME"
PING_STATUS=$?

if [ $PING_STATUS -ne 0 ]; then
  echo "WARNING: Could not ping host. This may indicate network connectivity issues."
  echo "Note: Some hosts don't respond to ping due to firewall settings."
fi

# Port connectivity test
section "Port Connectivity"
echo "Testing if port $PORT is open on $HOSTNAME..."
if command -v nc &> /dev/null; then
  nc -zv -w 5 "$HOSTNAME" "$PORT" 2>&1
  NC_STATUS=$?
  if [ $NC_STATUS -ne 0 ]; then
    echo "ERROR: Could not connect to $HOSTNAME on port $PORT"
    echo "This indicates that either:"
    echo "1. The server is not running on that port"
    echo "2. A firewall is blocking the connection"
    echo "3. The host is not reachable on the network"
  else
    echo "SUCCESS: Connection to $HOSTNAME on port $PORT succeeded"
  fi
else
  echo "WARNING: 'nc' (netcat) is not installed. Cannot test port connectivity."
  echo "Try running: telnet $HOSTNAME $PORT"
fi

# API endpoint tests
section "API Endpoints"
TODAY=$(date +%Y-%m-%d)

echo "Testing power data endpoint..."
POWER_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "${API_URL}/api/energy/data/power/${TODAY}")
echo "Status: $POWER_STATUS"
if [ "$POWER_STATUS" == "200" ]; then
  echo "Response sample:"
  curl -k -s "${API_URL}/api/energy/data/power/${TODAY}" | head -c 300
  echo "..."
fi
echo ""

echo "Testing gas data endpoint..."
GAS_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "${API_URL}/api/energy/data/gas/${TODAY}")
echo "Status: $GAS_STATUS"
if [ "$GAS_STATUS" == "200" ]; then
  echo "Response sample:"
  curl -k -s "${API_URL}/api/energy/data/gas/${TODAY}" | head -c 300
  echo "..."
fi
echo ""

echo "Testing summary endpoint..."
SUMMARY_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "${API_URL}/api/energy/summary/${TODAY}")
echo "Status: $SUMMARY_STATUS"
if [ "$SUMMARY_STATUS" == "200" ]; then
  echo "Response sample:"
  curl -k -s "${API_URL}/api/energy/summary/${TODAY}" | head -c 300
  echo "..."
fi
echo ""

# Check CORS headers
section "CORS Headers Check"
echo "Checking if CORS is enabled on the API..."
CORS_HEADERS=$(curl -k -s -I -X OPTIONS "${API_URL}/api/energy/data/power/${TODAY}" | grep -i "Access-Control-Allow")
if [ -z "$CORS_HEADERS" ]; then
  echo "WARNING: No CORS headers detected in the response."
  echo "This may cause browser access issues from Home Assistant."
  echo ""
  echo "The API server should include these headers:"
  echo "  Access-Control-Allow-Origin: *"
  echo "  Access-Control-Allow-Methods: GET, OPTIONS"
  echo "  Access-Control-Allow-Headers: Content-Type"
else
  echo "SUCCESS: CORS headers detected:"
  echo "$CORS_HEADERS"
fi

# Network diagnostic info
section "Network Information"
echo "Local network interfaces:"
ifconfig 2>/dev/null || ip addr

section "Recommendations"
echo "Based on the test results:"

if [ "$POWER_STATUS" == "000" ] || [ "$GAS_STATUS" == "000" ] || [ "$SUMMARY_STATUS" == "000" ]; then
  echo "1. Your device cannot connect to the API server. Possible issues:"
  echo "   - The API server is not running"
  echo "   - The host is unreachable on the network"
  echo "   - Firewall is blocking the connection"
  echo "   - The URL is incorrect (check protocol, host, and port)"
  echo ""
  echo "   Try accessing the API directly in a browser: ${API_URL}/api/energy/data/power/${TODAY}"
elif [ "$POWER_STATUS" == "200" ] && [ "$GAS_STATUS" == "200" ] && [ "$SUMMARY_STATUS" == "200" ]; then
  echo "1. API endpoints are accessible from this device!"
  if [ -z "$CORS_HEADERS" ]; then
    echo "2. However, CORS headers are missing which may cause browser access issues"
    echo "   Check your Apache/Nginx configuration to enable CORS"
  else
    echo "2. CORS headers are properly configured"
  fi
else
  echo "1. Some API endpoints are working, but others are not."
  echo "   Check the specific error codes for each endpoint above."
fi

echo ""
echo "For Home Assistant integration:"
echo "1. Make sure Home Assistant is on the same network as the API server"
echo "2. Use the IP address instead of hostname in the card configuration"
echo "3. Include the port number in the API URL if not using default ports"
echo "4. Check the browser console in Home Assistant for specific error messages"
