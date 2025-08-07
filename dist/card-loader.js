// Use this loader for development
(async () => {
  const energyPricesCard = document.createElement('script');
  energyPricesCard.src = '/local/ha-energy-panel/energy-prices-card.js';
  document.body.appendChild(energyPricesCard);
})();
