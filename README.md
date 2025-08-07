# Home Assistant Energy Panel Card

A custom card for Home Assistant that displays energy consumption data from REST API sensors.

## Installation

1. Copy the `energy-prices-card.js` file to your Home Assistant config directory under `www/ha-energy-panel/`
2. Add the card through the resource manager in Home Assistant:
   - URL: `/local/ha-energy-panel/energy-prices-card.js`
   - Type: JavaScript Module

## Configuration

### REST Sensors Setup

First, set up the REST sensors to pull data from your energy API:

```yaml
sensor:
  - platform: rest
    name: energy_power_data
    resource: http://100.107.164.25:9080/api/energy/data
    method: GET
    params:
      type: power
      date: "{{ now().strftime('%Y-%m-%d') }}"
    value_template: "{{ value_json }}"

  - platform: rest
    name: energy_gas_data
    resource: http://100.107.164.25:9080/api/energy/data
    method: GET
    params:
      type: gas
      date: "{{ now().strftime('%Y-%m-%d') }}"
    value_template: "{{ value_json }}"

  - platform: rest
    name: energy_available_dates
    resource: http://100.107.164.25:9080/api/energy/available-dates
    method: GET
    value_template: "{{ value_json }}"
```

### Date Selection Helper

```yaml
input_datetime:
  energy_chart_date:
    name: Energy Chart Date
    has_date: true
    has_time: false
    initial: "2025-08-07"
```

### Card Configuration

```yaml
type: custom:ha-energy-panel
title: Energy Consumption
power_entity: sensor.energy_power_data
gas_entity: sensor.energy_gas_data
dates_entity: sensor.energy_available_dates
date_input: input_datetime.energy_chart_date
```

### Date Change Automation

```yaml
automation:
  - alias: Update Energy Data When Date Changes
    trigger:
      - platform: state
        entity_id: input_datetime.energy_chart_date
    action:
      - service: homeassistant.update_entity
        entity_id: sensor.energy_power_data
      - service: homeassistant.update_entity
        entity_id: sensor.energy_gas_data
```

## Features

- Displays power and gas consumption data
- Date selection from available dates
- Integration with Home Assistant REST sensors
- Automatic updating when date changes

## Requirements

- Home Assistant with configured REST sensors
- Energy API (http://100.107.164.25:9080/api/energy/data)
