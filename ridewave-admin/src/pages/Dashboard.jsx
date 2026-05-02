import { useEffect, useMemo, useRef, useState } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase.js';

const quickAlerts = [
  { type: 'SOS', bus: 'BUS-022', text: 'Passenger collapse reported near seat 14.', time: '2m ago', severity: 'Critical' },
  { type: 'Report', bus: 'BUS-031', text: 'Driver skipped stop at Kadawatha.', time: '6m ago', severity: 'High' },
  { type: 'Report', bus: 'BUS-046', text: 'Route delay due to accident ahead.', time: '11m ago', severity: 'Medium' },
];

const todayBookings = [
  { id: 'BK-1024', amount: 420 },
  { id: 'BK-1025', amount: 180 },
  { id: 'BK-1026', amount: 420 },
  { id: 'BK-1027', amount: 280 },
];

const statusToMarkerClass = {
  Active: 'bus-marker-green',
  Idle: 'bus-marker-orange',
  Delayed: 'bus-marker-orange',
  Offline: 'bus-marker-red',
};

const statusToChipClass = {
  Active: 'chip-green',
  Idle: 'chip-amber',
  Delayed: 'chip-amber',
  Offline: 'chip-red',
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

const Dashboard = () => {
  const mapElRef = useRef(null);
  const mapRef = useRef(null);
  const markerMapRef = useRef({});
  const [buses, setBuses] = useState([]);
  const [searchValue, setSearchValue] = useState('');
  const [searchError, setSearchError] = useState('');
  const [selectedBus, setSelectedBus] = useState(null);
  const [mapError, setMapError] = useState('');

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'buses'), (snapshot) => {
      const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      setBuses(data);
    });
    return () => unsub();
  }, []);

  const activeBuses = useMemo(
    () => buses.filter((bus) => (bus.status || 'Idle') === 'Active'),
    [buses]
  );
  const delayedTrips = useMemo(
    () => buses.filter((bus) => (bus.status || 'Idle') === 'Delayed').length,
    [buses]
  );
  const totalRevenue = useMemo(
    () => todayBookings.reduce((sum, booking) => sum + booking.amount, 0),
    []
  );

  const stats = [
    { label: 'Live Buses', value: String(activeBuses.length), delta: 'GPS active now' },
    { label: 'Total Revenue (Today)', value: `LKR ${totalRevenue}`, delta: `${todayBookings.length} bookings` },
    { label: 'Total Bookings (Today)', value: String(todayBookings.length), delta: 'All routes' },
    { label: 'Quick Alerts', value: String(quickAlerts.length), delta: `${delayedTrips} delays` },
  ];

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
    <div className="dashboard">
      <section className="stats-grid">
        {stats.map((stat) => (
          <article key={stat.label} className="stat-card">
            <p>{stat.label}</p>
            <strong>{stat.value}</strong>
            <span>{stat.delta}</span>
          </article>
        ))}
      </section>
        <article className="panel map-preview">
          <div className="panel-head">
            <h2>Track Buses</h2>
            <span className="chip chip-blue">Live GPS</span>
          </div>

          <form className="map-search" onSubmit={handleSearch}>
            <div className="map-search-input">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M10 4a6 6 0 1 0 3.9 10.56l4.27 4.27 1.41-1.41-4.27-4.27A6 6 0 0 0 10 4Zm0 2a4 4 0 1 1 0 8 4 4 0 0 1 0-8Z" />
              </svg>
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
            <div className="real-map-canvas" ref={mapElRef} />
          )}

          <div className="live-map-legend">
            <span><i className="legend-dot good" /> Active</span>
            <span><i className="legend-dot warn" /> Delayed</span>
            <span><i className="legend-dot bad" /> Offline</span>
          </div>
        </article>


      <section className="panel">
        <div className="panel-head">
          <h2>Active Bus Details</h2>
          <span className="chip chip-green">{activeBuses.length} Running</span>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Bus Number</th>
                <th>Route</th>
                <th>Driver</th>
                <th>Passengers</th>
                <th>Current Location</th>
                <th>ETA</th>
              </tr>
            </thead>
            <tbody>
            {activeBuses.map((bus) => (
              <tr key={bus.id}>
                <td>{bus.busNo ?? bus.id}</td>
                <td>{bus.routeFrom ?? '-'} → {bus.routeTo ?? '-'}</td>
                <td>{bus.driverName ?? '-'}</td>
                <td>{bus.bookedSeats?.length ?? 0}</td>
                <td>{bus.currentLocation ?? '-'}</td>
                <td>{bus.eta ?? '-'}</td>
              </tr>
            ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
};

export default Dashboard;
