# Energy Prices Panel for Home Assistant

This custom card displays energy prices from your Energy API built with Symfony. It shows price charts and summary information to help you identify the cheapest times to use electricity.

## Features

- Interactive Chart.js visualization
- Select between power and gas prices
- Choose dates from the past 7 days
- Color-coded pricing (green for low, red for high, blue for negative prices)
- Price summary showing cheapest periods
- Average price display
- Responsive design that works on desktop and mobile

## Installation

### Method 1: HACS (Home Assistant Community Store) - Recommended

1. Make sure you have [HACS](https://hacs.xyz/) installed
2. Add this repository as a custom repository in HACS:
   - Go to HACS → Dashboard
   - Click the three dots in the upper right corner
   - Select "Custom repositories"
   - Add the URL of this repository
   - Select "Dashboard" as the category
3. Click "Install" on the Energy Prices Card
4. Add the card to your dashboard (see Configuration below)

### Method 2: Manual Installation

1. Download the `dist/energy-prices-card.js` file from this repository
2. Upload it to your Home Assistant instance in the `/config/www/energy-prices-card/` directory (create it if it doesn't exist)
3. Add the resource to your Home Assistant:
   - Go to Settings → Dashboards → Resources
   - Click "Add Resource"
   - Set URL to `/local/energy-prices-card/energy-prices-card.js`
   - Set Resource type to "JavaScript Module"
4. Restart Home Assistant
5. Add the card to your dashboard (see Configuration below)

## Configuration

Add the card to your dashboard with this configuration:

```yaml
type: 'custom:energy-prices-card'
api_url: 'https://100.107.164.25'  # Change this to your API URL
title: 'Energy Prices'
default_type: 'power'  # 'power' or 'gas'
```

### Options

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `api_url` | string | required | URL of your energy API |
| `title` | string | 'Energy Prices' | Card title |
| `default_type` | string | 'power' | Default energy type ('power' or 'gas') |

## Requirements

- Your Energy API must be accessible to Home Assistant
- The API must provide endpoints at:
  - `[api_url]/api/energy/data/{type}?date={date}`
  - `[api_url]/api/energy/summary/{date}`

## Troubleshooting

### Common Issues

1. **"Custom element doesn't exist: energy-prices-card"**
   - Make sure the resource is correctly loaded in Home Assistant
   - Check the browser console for JavaScript errors
   - Make sure you've added the resource in Settings → Dashboards → Resources

2. **"Error loading data: HTTP error! Status: 0"**
   - Your Home Assistant instance can't reach your API
   - Check that the API URL is correct and accessible from Home Assistant
   - Make sure CORS is enabled on your API

3. **Chart doesn't display properly**
   - Make sure Chart.js is loading correctly
   - Check the browser console for any errors

### Advanced Troubleshooting

- Check Home Assistant logs for JavaScript errors
- Test your API endpoints directly using curl or Postman
- Verify that your API returns CORS headers (Access-Control-Allow-Origin)

## Security Note

For enhanced security:
- Consider adding authentication to your API
- Use HTTPS for the API URL
- Only expose the API on trusted networks

## Screenshots

[Screenshots would be here]

## License

MIT License
