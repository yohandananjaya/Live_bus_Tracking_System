import { useEffect, useMemo, useRef, useState } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase.js';

const statusToMarkerClass = {
  Active: 'bus-marker-green',
  Delayed: 'bus-marker-orange',
  Offline: 'bus-marker-red',
  Idle: 'bus-marker-orange',
};



const ensureLeafletLoaded = () =>
  new Promise((resolve, reject) => {
    if (window.L) {
      resolve(window.L);
      return;
    }

    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }

    let script = document.getElementById('leaflet-js');

    if (!script) {
      script = document.createElement('script');
      script.id = 'leaflet-js';
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.async = true;
      script.onload = () => resolve(window.L);
      script.onerror = () => reject(new Error('Failed to load Leaflet'));
      document.body.appendChild(script);
      return;
    }

    script.addEventListener('load', () => resolve(window.L), { once: true });
    script.addEventListener('error', () => reject(new Error('Failed to load Leaflet')), { once: true });
  });

const toNumber = (v)=>{
  const n=typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n:null;
}

const LiveMap = () => {
 
  const mapElRef = useRef(null);
  const mapRef = useRef(null);
  const markerMapRef = useRef({});
  const [buses, setBuses] = useState([]);
  const [searchValue, setSearchValue] = useState('');
  const [searchError, setSearchError] = useState('');
  const [selectedBus, setSelectedBus] = useState(null);
  const [mapError, setMapError] = useState('');

  useEffect(() => {

    const q = collection(db, 'buses')

    const unsub = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      setBuses(data);
    });

    return () => unsub();
  }, []);


  useEffect(() => {
    let active = true;

    const initMap = async () => {
      try {
        const L = await ensureLeafletLoaded();
        if (!active || !mapElRef.current || mapRef.current) return;

        const map = L.map(mapElRef.current).setView([7.8731, 80.7718], 7);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          maxZoom: 19,
          attribution: '&copy; OpenStreetMap contributors',
        }).addTo(map);

        const markerMap = {};
        buses.forEach((bus) => {
          const lat = bus.latitude ?? bus.location?.lat ?? bus.coords?.[0];
          const lng = bus.longitude ?? bus.location?.lng ?? bus.coords?.[1];
          if (typeof lat !== 'number' || typeof lng !== 'number') return;

          const icon = L.divIcon({
            className: 'bus-marker-wrap',
            html: `<span class="bus-marker ${statusToMarkerClass[bus.status] || 'bus-marker-green'}"></span>`,
            iconSize: [22, 22],
            iconAnchor: [11, 11],
          });

          const marker = L.marker([lat, lng], { icon }).addTo(map);

          marker.bindPopup(
            `<strong>${bus.busNo ?? bus.id}</strong><br/>${bus.routeFrom ?? '-'} -> ${bus.routeTo ?? '-'}<br/>Status: ${bus.status ?? 'Idle'}`
          );
          markerMap[bus.id] = marker;
        });

        markerMapRef.current = markerMap;
        mapRef.current = map;
      } catch (error) {
        setMapError('Live map could not be loaded. Please check internet connection.');
      }
    };

    initMap();

    return () => {
      active = false;
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [buses]);

  useEffect(() => {
    if (!mapRef.current || !window.L) return;
    const L = window.L;
    const markerMap = markerMapRef.current;
    const seen = new Set();

    buses.forEach((bus) => {
      const lat = bus.location?.lat ?? bus.location?.latitude ?? bus.coords?.[0];
      const lng = bus.location?.lng ?? bus.location?.longitude ?? bus.coords?.[1];
      if (typeof lat !== 'number' || typeof lng !== 'number') return;

      const icon = L.divIcon({
        className: 'bus-marker-wrap',
        html: `<span class="bus-marker ${statusToMarkerClass[bus.status] || 'bus-marker-green'}"></span>`,
        iconSize: [22, 22],
        iconAnchor: [11, 11],
      });

      if (markerMap[bus.id]) {
        markerMap[bus.id].setLatLng([lat, lng]);
        markerMap[bus.id].setIcon(icon);
      } else {
        const marker = L.marker([lat, lng], { icon }).addTo(mapRef.current);
        marker.bindPopup(
          `<strong>${bus.busNumber ?? bus.id}</strong><br/>${bus.route?.from ?? '-'} -> ${bus.route?.to ?? '-'}<br/>Status: ${bus.status ?? 'Active'}`
        );
        markerMap[bus.id] = marker;
      }
      seen.add(bus.id);
    });

    Object.keys(markerMap).forEach((key) => {
      if (!seen.has(key)) {
        markerMap[key].remove();
        delete markerMap[key];
      }
    });
  }, [buses]);
  const handleSearch = (event) => {
    event.preventDefault();
    const busNo = searchValue.trim().toUpperCase();
    if (!busNo) return;

    const bus = buses.find((item) => (item.busNo || '').toUpperCase() === busNo);
    if (!bus) {
      setSelectedBus(null);
      setSearchError('Bus number not found.');
      return;
    }

    setSearchError('');
    setSelectedBus(bus);

    const lat = bus.latitude ?? bus.location?.lat ?? bus.coords?.[0];
    const lng = bus.longitude ?? bus.location?.lng ?? bus.coords?.[1];

    if (mapRef.current && typeof lat === 'number' && typeof lng === 'number') {
      mapRef.current.flyTo([lat, lng], 13, { duration: 1.2 });
      const marker = markerMapRef.current[bus.id];
      if (marker) marker.openPopup();
    }
  };
  return (
    <section className="panelNew">
      <div className="panel-head" style={{marginBottom:"15px"}}>
        <h2>Live Tracking Map</h2>
        <span className="chip chip-blue">Firebase live feed</span>
      </div>
       
          <form className="map-search" onSubmit={handleSearch}>
            <div className="map-search-input" style={{marginBottom:"15px"}}>

              <input
                type="text"
                placeholder="Search bus number (e.g. BUS-022)"
                value={searchValue}
                onChange={(event) => setSearchValue(event.target.value)}
              />
            </div>
            <button className="action-btn" type="submit">Search</button>
          </form>

          {searchError && <p className="form-notice error">{searchError}</p>}

          {selectedBus && (
            <div className="search-result-card">
              <strong>{selectedBus.busNo ?? selectedBus.id}</strong>
              <p>
                Status:{' '}
                <span className={`chip ${statusToChipClass[selectedBus.status] || 'chip-blue'}`}>
                  {selectedBus.status ?? 'Idle'}
                </span>
              </p>
              <p>Route: {selectedBus.routeFrom ?? '-'} → {selectedBus.routeTo ?? '-'}</p>
            </div>
          )}

          {mapError ? (
            <p className="form-notice error">{mapError}</p>
          ) : (
            <div className="real-map-canvasNew" ref={mapElRef} />
          )}

          <div className="live-map-legend" style={{marginTop:"10px"}}>
            <span><i className="legend-dot good" /> Active</span>
            <span><i className="legend-dot warn" /> Delayed</span>
            <span><i className="legend-dot bad" /> Offline</span>
          </div>
 
    </section>
  );
};

export default LiveMap;
