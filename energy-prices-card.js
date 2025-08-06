class EnergyPricesCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this._config = {};
    this._chart = null;
  }

  setConfig(config) {
    if (!config.api_url) {
      throw new Error('You need to define an api_url');
    }
    
    this._config = {
      api_url: config.api_url || 'https://100.107.164.25',
      title: config.title || 'Energy Prices',
      ...config
    };
  }

  static getStubConfig() {
    return {
      api_url: 'https://100.107.164.25',
      title: 'Energy Prices',
      default_type: 'power'
    };
  }

  set hass(hass) {
    this._hass = hass;
    if (!this._initialized) {
      this._initialize();
    }
  }

  async _initialize() {
    this._initialized = true;
    
    // Set up the card HTML structure
    this.shadowRoot.innerHTML = `
      <ha-card header="${this._config.title}">
        <div class="card-content">
          <style>
            .chart-container {
              width: 100%;
              height: 350px;
              position: relative;
              margin-bottom: 16px;
            }
            .controls {
              display: flex;
              justify-content: space-between;
              gap: 10px;
              margin-bottom: 16px;
            }
            .control-group {
              flex: 1;
            }
            select, button {
              padding: 8px 12px;
              border-radius: 4px;
              border: 1px solid var(--divider-color);
              background-color: var(--card-background-color);
              color: var(--primary-text-color);
              font-size: 14px;
              width: 100%;
            }
            button {
              background-color: var(--primary-color);
              color: var(--text-primary-color);
              border: none;
              cursor: pointer;
              text-transform: uppercase;
            }
            button:hover {
              background-color: var(--primary-color-light);
            }
            .error {
              color: var(--error-color);
              margin: 16px 0;
            }
            .summary {
              margin: 16px 0;
              padding: 12px;
              background-color: var(--secondary-background-color);
              border-radius: 4px;
            }
            .loading {
              display: flex;
              justify-content: center;
              align-items: center;
              height: 350px;
            }
            .loading::after {
              content: "";
              width: 40px;
              height: 40px;
              border: 5px solid var(--divider-color);
              border-top: 5px solid var(--primary-color);
              border-radius: 50%;
              animation: spin 1s linear infinite;
            }
            @keyframes spin {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
            label {
              display: block;
              margin-bottom: 4px;
              font-weight: 500;
            }
            .hidden {
              display: none;
            }
          </style>
          
          <div class="controls">
            <div class="control-group">
              <label for="energy-type">Energy Type:</label>
              <select id="energy-type">
                <option value="power">Power</option>
                <option value="gas">Gas</option>
              </select>
            </div>
            
            <div class="control-group">
              <label for="energy-date">Date:</label>
              <select id="energy-date"></select>
            </div>
            
            <div class="control-group">
              <label>&nbsp;</label>
              <button id="update-chart">Update Chart</button>
            </div>
          </div>
          
          <div class="summary hidden" id="energy-summary"></div>
          
          <div class="chart-container">
            <div class="loading" id="loading-indicator"></div>
            <canvas id="energyChart"></canvas>
          </div>
          
          <div class="error hidden" id="error-message"></div>
        </div>
      </ha-card>
    `;

    // Wait for Chart.js to load
    await this._loadChartJS();
    
    // Set up event listeners
    this._setupEventListeners();
    
    // Initialize the chart
    await this._setupDateOptions();
    this._createOrUpdateChart();
  }

  async _loadChartJS() {
    // Check if Chart.js is already loaded
    if (window.Chart) return;
    
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js';
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Failed to load Chart.js'));
      document.head.appendChild(script);
    });
  }

  _setupEventListeners() {
    const updateButton = this.shadowRoot.getElementById('update-chart');
    updateButton.addEventListener('click', () => {
      this._createOrUpdateChart();
    });

    // Set default type if configured
    if (this._config.default_type) {
      const typeSelect = this.shadowRoot.getElementById('energy-type');
      typeSelect.value = this._config.default_type;
    }
  }

  async _setupDateOptions() {
    const dateSelect = this.shadowRoot.getElementById('energy-date');
    
    // Add dates for the last 7 days
    const today = new Date();
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      
      const dateString = date.toISOString().split('T')[0];
      const option = document.createElement('option');
      option.value = dateString;
      option.textContent = dateString;
      
      if (i === 0) option.selected = true;
      
      dateSelect.appendChild(option);
    }
  }

  async _createOrUpdateChart() {
    try {
      // Show loading
      this.shadowRoot.getElementById('loading-indicator').classList.remove('hidden');
      this.shadowRoot.getElementById('error-message').classList.add('hidden');
      
      // Get selected values
      const typeSelect = this.shadowRoot.getElementById('energy-type');
      const dateSelect = this.shadowRoot.getElementById('energy-date');
      const selectedType = typeSelect.value;
      const selectedDate = dateSelect.value;

      // Fetch data
      const energyData = await this._fetchEnergyData(selectedType, selectedDate);
      
      // Fetch and display summary
      await this._fetchAndDisplaySummary(selectedDate);
      
      // Process data for chart
      const prices = energyData.data.Prices;
      const labels = prices.map(entry => {
        const time = entry.readingDate.split('T')[1].substring(0, 5);
        return time;
      });
      
      const priceData = prices.map(entry => entry.price);
      
      // Calculate min and max for better coloring
      const minPrice = Math.min(...priceData);
      const maxPrice = Math.max(...priceData);
      
      // Generate colors based on price values (green for low, red for high, blue for negative)
      const backgroundColors = priceData.map(price => {
        if (price < 0) return 'rgba(54, 162, 235, 0.5)'; // Blue for negative (money back)
        
        // For positive values, gradiate from green to red
        const normalizedPrice = maxPrice === 0 ? 0 : (price / maxPrice);
        const red = Math.round(255 * normalizedPrice);
        const green = Math.round(255 * (1 - normalizedPrice));
        return `rgba(${red}, ${green}, 0, 0.5)`;
      });
      
      const borderColors = priceData.map(price => {
        if (price < 0) return 'rgba(54, 162, 235, 1)'; // Blue for negative (money back)
        
        // For positive values, gradiate from green to red
        const normalizedPrice = maxPrice === 0 ? 0 : (price / maxPrice);
        const red = Math.round(255 * normalizedPrice);
        const green = Math.round(255 * (1 - normalizedPrice));
        return `rgba(${red}, ${green}, 0, 1)`;
      });
      
      // Get canvas context
      const ctx = this.shadowRoot.getElementById('energyChart').getContext('2d');
      
      // If chart already exists, destroy it
      if (this._chart) {
        this._chart.destroy();
      }
      
      // Create new chart
      this._chart = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: labels,
          datasets: [{
            label: `${selectedType.charAt(0).toUpperCase() + selectedType.slice(1)} Price (€)`,
            data: priceData,
            backgroundColor: backgroundColors,
            borderColor: borderColors,
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: {
              title: {
                display: true,
                text: 'Time (Hour)'
              }
            },
            y: {
              title: {
                display: true,
                text: 'Price (€)'
              }
            }
          },
          plugins: {
            tooltip: {
              callbacks: {
                label: function(context) {
                  let label = context.dataset.label || '';
                  if (label) {
                    label += ': ';
                  }
                  const price = context.raw;
                  label += `€${price.toFixed(2)}`;
                  return label;
                }
              }
            },
            title: {
              display: true,
              text: `${selectedType.charAt(0).toUpperCase() + selectedType.slice(1)} Prices - ${selectedDate}`
            },
            subtitle: {
              display: true,
              text: `Average: €${energyData.data.average.toFixed(2)}`
            }
          }
        }
      });
      
      // Hide loading
      this.shadowRoot.getElementById('loading-indicator').classList.add('hidden');
    } catch (error) {
      console.error('Error creating chart:', error);
      const errorElement = this.shadowRoot.getElementById('error-message');
      errorElement.textContent = `Error loading data: ${error.message}`;
      errorElement.classList.remove('hidden');
      this.shadowRoot.getElementById('loading-indicator').classList.add('hidden');
    }
  }

  async _fetchEnergyData(type, date) {
    const apiUrl = this._config.api_url;
    const url = `${apiUrl}/api/energy/data/${type}?date=${date}`;
    
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    return await response.json();
  }

  async _fetchAndDisplaySummary(date) {
    try {
      const apiUrl = this._config.api_url;
      const url = `${apiUrl}/api/energy/summary/${date}`;
      
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      
      const summaryData = await response.json();
      const summaryElement = this.shadowRoot.getElementById('energy-summary');
      
      if (summaryData && summaryData.message) {
        summaryElement.textContent = summaryData.message;
        summaryElement.classList.remove('hidden');
      } else {
        summaryElement.classList.add('hidden');
      }
    } catch (error) {
      console.error('Error fetching summary:', error);
      // Don't show error for summary, just hide the element
      this.shadowRoot.getElementById('energy-summary').classList.add('hidden');
    }
  }

  getCardSize() {
    return 4; // Card takes up 4 rows
  }
}

customElements.define('energy-prices-card', EnergyPricesCard);

window.customCards = window.customCards || [];
window.customCards.push({
  type: "energy-prices-card",
  name: "Energy Prices Card",
  description: "A card that displays energy prices from your energy API"
});
