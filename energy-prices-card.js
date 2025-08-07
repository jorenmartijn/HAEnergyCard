/**
 * Energy Panel Card
 * A custom card that displays energy data from Home Assistant REST sensors
 */
class HaEnergyPanel extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this._config = {};
  }

  static get properties() {
    return {
      hass: {},
      config: {}
    };
  }

  setConfig(config) {
    if (!config.power_entity || !config.gas_entity || !config.dates_entity) {
      throw new Error('You need to define power_entity, gas_entity and dates_entity');
    }
    this._config = config;
  }

  getCardSize() {
    return 5;
  }

  _updateData() {
    const power = this.hass.states[this._config.power_entity];
    const gas = this.hass.states[this._config.gas_entity];
    const dates = this.hass.states[this._config.dates_entity];

    let powerData = {};
    let gasData = {};
    let availableDates = { power: [], gas: [], common: [] };

    if (power && power.state !== 'unavailable' && power.state !== 'unknown') {
      try {
        powerData = JSON.parse(power.state);
      } catch (e) {
        console.error('Error parsing power data', e);
      }
    }

    if (gas && gas.state !== 'unavailable' && gas.state !== 'unknown') {
      try {
        gasData = JSON.parse(gas.state);
      } catch (e) {
        console.error('Error parsing gas data', e);
      }
    }

    if (dates && dates.state !== 'unavailable' && dates.state !== 'unknown') {
      try {
        availableDates = JSON.parse(dates.state);
      } catch (e) {
        console.error('Error parsing dates data', e);
      }
    }

    return { powerData, gasData, availableDates };
  }

  _renderDateSelector(availableDates) {
    const dates = availableDates.common || [];
    if (!dates.length) return 'No dates available';
    
    const options = dates.map(date => 
      `<option value="${date}">${date}</option>`
    ).join('');
    
    return `
      <div class="date-selector">
        <select id="date-select">
          ${options}
        </select>
      </div>
    `;
  }

  _renderChart(powerData, gasData) {
    // This is a placeholder. In a real implementation, 
    // we would render a chart using a library like Chart.js
    
    return `
      <div class="chart-container">
        <div id="energy-chart">
          <p>Power data available: ${Object.keys(powerData).length > 0 ? 'Yes' : 'No'}</p>
          <p>Gas data available: ${Object.keys(gasData).length > 0 ? 'Yes' : 'No'}</p>
          <p>To render an actual chart, include Chart.js and render it in connectedCallback</p>
        </div>
      </div>
    `;
  }

  _handleDateChange(e) {
    const newDate = e.target.value;
    
    // Call services to update the sensors with new date
    this.hass.callService('homeassistant', 'update_entity', {
      entity_id: this._config.power_entity
    });
    
    this.hass.callService('homeassistant', 'update_entity', {
      entity_id: this._config.gas_entity
    });
    
    // You could also call a service to update the input_datetime if you're using one
    if (this._config.date_input) {
      this.hass.callService('input_datetime', 'set_datetime', {
        entity_id: this._config.date_input,
        date: newDate
      });
    }
  }

  connectedCallback() {
    this.shadowRoot.addEventListener('change', e => {
      if (e.target.id === 'date-select') {
        this._handleDateChange(e);
      }
    });
    
    // Initial update
    this.updated(new Map([['hass', this.hass]]));
  }

  updated(changedProps) {
    if (changedProps.has('hass')) {
      const { powerData, gasData, availableDates } = this._updateData();
      
      // Update the UI
      this.render(powerData, gasData, availableDates);
    }
  }

  render(powerData, gasData, availableDates) {
    this.shadowRoot.innerHTML = `
      <ha-card header="${this._config.title || 'Energy Panel'}">
        <div class="card-content">
          ${this._renderDateSelector(availableDates)}
          ${this._renderChart(powerData, gasData)}
        </div>
      </ha-card>
      <style>
        ha-card {
          width: 100%;
          padding: 16px;
        }
        .card-content {
          padding: 16px;
        }
        .date-selector {
          margin-bottom: 16px;
        }
        .chart-container {
          height: 300px;
          width: 100%;
        }
      </style>
    `;
  }
}

customElements.define('ha-energy-panel', HaEnergyPanel);

window.customCards = window.customCards || [];
window.customCards.push({
  type: 'ha-energy-panel',
  name: 'Energy Panel Card',
  description: 'A card that displays energy data from Home Assistant REST sensors'
});
