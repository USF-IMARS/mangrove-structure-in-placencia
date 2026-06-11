(function () {
  const regionFiles = {
    lower: "lower.xlsx",
    upper: "upper.xlsx",
    "main creek": "main-creek.xlsx",
  };

  const regionStyles = {
    lower: { color: "#d7191c", fillColor: "#fdae61", weight: 2, fillOpacity: 0.45 },
    upper: { color: "#2c7bb6", fillColor: "#abd9e9", weight: 2, fillOpacity: 0.45 },
    "main creek": { color: "#1a9641", fillColor: "#a6d96a", weight: 2, fillOpacity: 0.45 },
  };

  const mapEl = document.getElementById("sector-map");
  const panelEl = document.getElementById("sector-table-panel");
  if (!mapEl || !panelEl) return;

  const dataRoot = mapEl.dataset.root || "data";
  const tableRoot = `${dataRoot}/sector-tables`;
  const geojsonUrl = `${dataRoot}/placencia-sectors-map.geojson`;

  const map = L.map(mapEl, { scrollWheelZoom: false }).setView([16.62, -88.34], 12);

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    maxZoom: 19,
  }).addTo(map);

  let activeLayer = null;

  function titleCase(region) {
    return region.replace(/\b\w/g, (c) => c.toUpperCase());
  }

  function setPanelMessage(html) {
    panelEl.innerHTML = html;
  }

  function loadSectorTable(region) {
    const file = regionFiles[region];
    if (!file) {
      setPanelMessage(`<p>No table configured for region <strong>${region}</strong>.</p>`);
      return;
    }

    setPanelMessage(`<p>Loading <strong>${titleCase(region)}</strong>…</p>`);

    fetch(`${tableRoot}/${file}`)
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return response.arrayBuffer();
      })
      .then((buffer) => {
        const workbook = XLSX.read(buffer, { type: "array" });
        const sheet = workbook.Sheets[workbook.SheetNames[0]];
        const tableHtml = XLSX.utils.sheet_to_html(sheet, { id: "sector-data-table", editable: false });
        setPanelMessage(
          `<h3 class="sector-table-title">${titleCase(region)} lagoon</h3>${tableHtml}`
        );
      })
      .catch((error) => {
        setPanelMessage(
          `<p>Could not load <strong>${file}</strong>: ${error.message}</p>`
        );
      });
  }

  function onEachFeature(feature, layer) {
    const region = feature.properties.region;
    const style = regionStyles[region] || { color: "#555", fillColor: "#ccc", weight: 2, fillOpacity: 0.4 };
    layer.setStyle(style);

    layer.bindTooltip(titleCase(region), { sticky: true, direction: "top" });

    layer.on({
      mouseover: (event) => {
        event.target.setStyle({ weight: 3, fillOpacity: 0.65 });
      },
      mouseout: (event) => {
        if (activeLayer !== event.target) {
          event.target.setStyle(style);
        }
      },
      click: (event) => {
        if (activeLayer && activeLayer !== event.target) {
          const prevRegion = activeLayer.feature.properties.region;
          const prevStyle = regionStyles[prevRegion] || style;
          activeLayer.setStyle(prevStyle);
        }
        activeLayer = event.target;
        event.target.setStyle({ weight: 4, fillOpacity: 0.75 });
        loadSectorTable(region);
      },
    });
  }

  fetch(geojsonUrl)
    .then((response) => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response.json();
    })
    .then((geojson) => {
      const layer = L.geoJSON(geojson, { onEachFeature }).addTo(map);
      map.fitBounds(layer.getBounds(), { padding: [20, 20] });
    })
    .catch((error) => {
      setPanelMessage(`<p>Could not load sector map: ${error.message}</p>`);
    });
})();
