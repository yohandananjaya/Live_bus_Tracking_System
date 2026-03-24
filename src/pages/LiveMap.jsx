import { useEffect, useRef, useState } from 'react';
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

const LiveMap = () => {
  const mapElRef = useRef(null);
  const mapRef = useRef(null);
  const markerMapRef = useRef({});
  const [buses, setBuses] = useState([]);
  const [mapError, setMapError] = useState('');

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'buses'), (snapshot) => {
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
          maxZoom: 18,
          attribution: '&copy; OpenStreetMap contributors',
        }).addTo(map);

        mapRef.current = map;
      } catch (_error) {
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
  }, []);

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

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Live Tracking Map</h2>
        <span className="chip chip-blue">Firebase live feed</span>
      </div>

      {mapError ? (
        <p className="form-notice error">{mapError}</p>
      ) : (
        <div className="real-map-canvas live-map-canvas" ref={mapElRef} />
      )}

      <div className="live-map-legend">
        <span><i className="legend-dot good" /> Active</span>
        <span><i className="legend-dot warn" /> Idle / Delayed</span>
        <span><i className="legend-dot bad" /> Offline</span>
      </div>
    </section>
  );
};

export default LiveMap;
