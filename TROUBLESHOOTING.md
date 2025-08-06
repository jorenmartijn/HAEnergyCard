# Troubleshooting API Connectivity

This guide will help you troubleshoot connectivity issues between your Home Assistant instance and your Energy API.

## Common Issues and Solutions

### 1. URL Configuration

Make sure you're using the correct URL format in your card configuration:

```yaml
type: 'custom:energy-prices-card'
api_url: 'https://your-server-ip:83'  # Include the port if needed
title: 'Energy Prices'
default_type: 'power'
```

- The URL should include the correct protocol (`http://` or `https://`)
- If your server uses a non-standard port, include it in the URL
- Use the IP address rather than hostname if DNS resolution might be an issue

### 2. CORS Configuration

If Home Assistant is running on a different domain or port than your API, you need to enable CORS on your API server.

Your Apache configuration already includes CORS headers:

```apache
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type, Authorization"
```

Make sure the `headers` module is enabled in Apache:

```bash
sudo a2enmod headers
sudo service apache2 restart
```

### 3. SSL Certificate Issues

If you're using self-signed certificates:

- For testing, you can use HTTP instead of HTTPS to avoid certificate issues
- In Home Assistant, you may need to disable SSL verification
- For browser testing, you'll need to accept the certificate warning

### 4. Network Connectivity

Ensure Home Assistant can reach your API server:

- If Home Assistant is running in Docker, make sure the container has network access
- Check if firewalls are blocking access between the devices
- Verify both devices are on the same network or can route to each other

### 5. API Endpoint Structure

The card expects endpoints in the following format:

- `[api_url]/api/energy/data/power/{date}`
- `[api_url]/api/energy/data/gas/{date}`
- `[api_url]/api/energy/summary/{date}`

Make sure your API endpoints match these formats.

## Using the Test Tools

### API Test Script

Run the included test script to diagnose connectivity issues:

```bash
./test_api.sh https://your-server-ip:83
```

This will check each endpoint and display the response.

### Browser Test Page

Open `test_card.html` in a web browser to test the card directly:

1. Enter your API URL including protocol and port
2. Click "Load Card"
3. Check the debug output for errors

## Check Browser Developer Console

When using the card in Home Assistant, open your browser's developer console to see detailed error messages:

1. Right-click on the page and select "Inspect" or "Inspect Element"
2. Go to the "Console" tab
3. Look for errors related to the card or API requests

## Testing the API Directly

You can test your API endpoints directly with curl:

```bash
# Test power data endpoint
curl -k "https://your-server-ip:83/api/energy/data/power/2025-08-06"

# Test gas data endpoint
curl -k "https://your-server-ip:83/api/energy/data/gas/2025-08-06"

# Test summary endpoint
curl -k "https://your-server-ip:83/api/energy/summary/2025-08-06"
```

The `-k` flag disables SSL certificate verification, which is useful for self-signed certificates.

## Checking API Response Format

The card expects the API to return JSON data in a specific format. Make sure your API responses match what the card expects.

For data endpoints:
```json
{
  "prices": [
    {"hour": 0, "price": 0.123},
    {"hour": 1, "price": 0.145},
    ...
  ],
  "date": "2025-08-06",
  "type": "power"
}
```

For summary endpoint:
```json
{
  "averagePrice": 0.123,
  "lowestPrice": 0.089,
  "highestPrice": 0.210,
  "bestHours": [3, 4, 5],
  "date": "2025-08-06"
}
```
