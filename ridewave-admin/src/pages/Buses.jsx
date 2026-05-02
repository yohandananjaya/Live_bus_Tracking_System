import { useEffect, useMemo, useState } from 'react';
import { addDoc, collection, deleteDoc, doc, onSnapshot, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase.js';

const initialDraft = {
  busNo: '',
  busChasisNo:'',
  busType: '',
  totalSeats: '',
  ownerName: '',
  ownerNIC: '',
  ownerContact: '',
  accessCode: '',
  ownerAddress: '',
  
};

const statusOrder = { Active: 0, Idle: 1, Delayed: 2, Offline: 3 };

const generateAccessCode = () => {
  const pool = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const code = Array.from({ length: 4 }, () => pool[Math.floor(Math.random() * pool.length)]).join('');
  return `RW-${code}`;
};

const Buses = () => {
  const [buses, setBuses] = useState([]);
  const [query, setQuery] = useState('');
  const [sortBy, setSortBy] = useState('busNo');
  const [statusFilter, setStatusFilter] = useState('All');
  const [draft, setDraft] = useState(initialDraft);
  const [editingId, setEditingId] = useState(null);
  const [editingBus, setEditingBus] = useState(null);
  const [formError, setFormError] = useState('');
  const [notice, setNotice] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'buses'), (snapshot) => {
      const data = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }));
      setBuses(data);
    });
    return () => unsub();
  }, []);

  const summary = useMemo(() => {
    const total = buses.length;
    const idle = buses.filter((bus) => (bus.status || 'Idle') === 'Idle').length;
    const active = buses.filter((bus) => bus.status === 'Active').length;
    const offline = buses.filter((bus) => bus.status === 'Offline').length;
    return { total, idle, active, offline };
  }, [buses]);

  const filteredBuses = useMemo(() => {
    const search = query.trim().toLowerCase();

    return buses
      .filter((bus) => statusFilter === 'All' || (bus.status || 'Idle') === statusFilter)
      .filter((bus) => {
        if (!search) return true;
        const haystack = `${bus.busNo} ${bus.busType} ${bus.ownerName} ${bus.ownerNIC} ${bus.driverContact}`
          .toLowerCase();
        return haystack.includes(search);
      })
      .sort((a, b) => {
        if (sortBy === 'status') {
          return (statusOrder[a.status] ?? 9) - (statusOrder[b.status] ?? 9);
        }
        return String(a[sortBy] || '').localeCompare(String(b[sortBy] || ''));
      });
  }, [buses, query, sortBy, statusFilter]);

  const resetDraft = () => {
    setDraft(initialDraft);
    setEditingId(null);
    setEditingBus(null);
    setFormError('');
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setFormError('');
    setNotice('');

    if (!draft.busNo || !draft.busType || !draft.totalSeats || !draft.ownerName || !draft.ownerNIC || !draft.driverContact) {
      setFormError('Please fill all required fields.');
      return;
    }

    if (!/^[A-Z]{2}-\d{4}$/i.test(draft.busNo.trim())) {
      setFormError('Bus number must use format ND-4532.');
      return;
    }

    if (!draft.totalSeats || Number(draft.totalSeats) <= 0) {
      setFormError('Total seats must be a positive number.');
      return;
    }

    const payload = {
      busNo: draft.busNo.trim().toUpperCase(),
      chasisNo:draft.busChasisNo.trim(),
      busType: draft.busType.trim(),
      totalSeats: Number(draft.totalSeats),
      ownerName: draft.ownerName.trim(),
      ownerNIC: draft.ownerNIC.trim(),
      ownerContact: draft.ownerContact.trim(),
      accessCode: draft.accessCode || generateAccessCode(),
      routeFrom: editingBus?.routeFrom ?? '',
      routeTo: editingBus?.routeTo ?? '',
      stops: editingBus?.stops ?? [],
      price: editingBus?.price ?? '0',
      status: editingBus?.status ?? 'Idle',
      totalRevenue: editingBus?.totalRevenue ?? 0,
      bookedSeats: editingBus?.bookedSeats ?? [],
      latitude: editingBus?.latitude ?? 0.0,
      longitude: editingBus?.longitude ?? 0.0,
      updatedAt: serverTimestamp(),
    };

    setIsSubmitting(true);
    try {
      if (editingId) {
        await updateDoc(doc(db, 'buses', editingId), payload);
        setNotice(`${payload.busNo} updated. Access code: ${payload.accessCode}`);
      } else {
        await addDoc(collection(db, 'buses'), {
          ...payload,
          status: 'Idle',
          createdAt: serverTimestamp(),
        });
        setNotice(`${payload.busNo} added. Driver access code: ${payload.accessCode}`);
      }

      resetDraft();
    } catch (_error) {
      setFormError('Unable to save the bus. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEdit = (bus) => {
    setEditingId(bus.id);
    setEditingBus(bus);
    setDraft({
      busNo: bus.busNo || '',
      busType: bus.busType || '',
      totalSeats: bus.totalSeats ?? '',
      ownerName: bus.ownerName || '',
      ownerNIC: bus.ownerNIC || '',
      ownerContact: bus.ownerContact || '',
      accessCode: bus.accessCode || '',
    });
    setNotice('');
  };

  const handleDelete = async (busId, label) => {
    setNotice('');
    try {
      await deleteDoc(doc(db, 'buses', busId));
      setNotice(`${label} deleted from fleet.`);
    } catch (_error) {
      setFormError('Unable to delete bus. Please try again.');
    }
  };

  const regenerateAccessCode = () => {
    setDraft((current) => ({ ...current, accessCode: generateAccessCode() }));
  };

  return (
    <section className="panel">
      <div className="fleet-header">
        <div>
          <h2>Fleet Management</h2>
          <p className="fleet-subtitle">Add new buses, register owners, and issue driver access codes.</p>
        </div>
        <div className="fleet-head-actions">
          <button className="ghost-btn" type="button" onClick={resetDraft}>
            Clear Form
          </button>
        </div>
      </div>

      <div className="fleet-stats">
        <article className="fleet-stat">
          <p>Total Fleet</p>
          <strong>{summary.total}</strong>
        </article>
        <article className="fleet-stat">
          <p>Idle</p>
          <strong>{summary.idle}</strong>
        </article>
        <article className="fleet-stat">
          <p>Active</p>
          <strong>{summary.active}</strong>
        </article>
        <article className="fleet-stat">
          <p>Offline</p>
          <strong>{summary.offline}</strong>
        </article>
      </div>

      {notice && <p className="form-notice success">{notice}</p>}

      <form className="form-panel" onSubmit={handleSubmit}>
        <h3 className="routes-form-title">{editingId ? 'Edit Bus Details' : 'Add New Bus'}</h3>

        <div className="form-grid">
          <label className="form-field">
            <span>Bus Number</span>
            <input
              type="text"
              placeholder="ND-4532"
              value={draft.busNo}
              onChange={(event) => setDraft((current) => ({ ...current, busNo: event.target.value }))}
              required
            />
          </label>
          <label className="form-field">
            <span>Bus Type / Model</span>
            <input
              type="text"
              placeholder="Normal - Leyland"
              value={draft.busType}
              onChange={(event) => setDraft((current) => ({ ...current, busType: event.target.value }))}
              required
            />
          </label>
          <label className="form-field">
            <span>Total Seats</span>
            <input
              type="number"
              min="1"
              placeholder="54"
              value={draft.totalSeats}
              onChange={(event) => setDraft((current) => ({ ...current, totalSeats: event.target.value }))}
              required
            />
          </label>
          
          <label className="form-field">
            <span>Owner Name</span>
            <input
              type="text"
              placeholder="Nimal Kumara"
              value={draft.ownerName}
              onChange={(event) => setDraft((current) => ({ ...current, ownerName: event.target.value }))}
              required
            />
          </label>
        </div>

        <div className="form-grid">
          <label className="form-field">
            <span>Owner NIC / ID Number</span>
            <input
              type="text"
              placeholder="198512345678"
              value={draft.ownerNIC}
              onChange={(event) => setDraft((current) => ({ ...current, ownerNIC: event.target.value }))}
              required
            />
          </label>
          <label className="form-field">
            <span>Owner Contact Number</span>
            <input
              type="text"
              placeholder="0712345678"
              value={draft.ownerContact}
              onChange={(event) => setDraft((current) => ({ ...current, ownerContact: event.target.value }))}
              required
            />
          </label>
          
          <label className="form-field">
            <span>Owner Address</span>
            <input
              type="text"
              placeholder="67/A, Hapugala, Galle"
              value={draft.driverContact}
              onChange={(event) => setDraft((current) => ({ ...current, driverContact: event.target.value }))}
              required
            />
          </label>
          <label className="form-field">
            <span>Owner Contact Number</span>
            <input
              type="text"
              placeholder="0712345678"
              value={draft.driverContact}
              onChange={(event) => setDraft((current) => ({ ...current, driverContact: event.target.value }))}
              required
            />
          </label>
          
        </div>

        <div className="access-code-row">
          <div>
            <p className="panel-copy">
              Driver Access Code will be generated automatically when you save this bus.
            </p>
            {draft.accessCode && (
              <p className="code-preview">
                Current Code: <span>{draft.accessCode}</span>
              </p>
            )}
          </div>
          {editingId && (
            <button type="button" className="ghost-btn" onClick={regenerateAccessCode}>
              Regenerate Code
            </button>
          )}
        </div>

        {formError && <p className="form-notice error">{formError}</p>}

        <div className="form-actions">
          <button type="button" className="ghost-btn" onClick={resetDraft}>
            Reset
          </button>
          <button type="submit" className="action-btn" disabled={isSubmitting}>
            {isSubmitting ? 'Saving...' : editingId ? 'Update Bus' : 'Generate Code & Save'}
          </button>
        </div>
      </form>

      <div className="fleet-toolbar">
        <input
          type="search"
          placeholder="Search bus number, owner, or type..."
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option>All</option>
          <option>Idle</option>
          <option>Active</option>
          <option>Delayed</option>
          <option>Offline</option>
        </select>
        <select value={sortBy} onChange={(event) => setSortBy(event.target.value)}>
          <option value="busNo">Sort by Bus Number</option>
          <option value="ownerName">Sort by Owner</option>
          <option value="status">Sort by Status</option>
        </select>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Bus Number</th>
              <th>Bus Type</th>
              <th>Seats</th>
              <th>Owner</th>
              <th>Owner NIC</th>
              <th>Contact</th>
              <th>Status</th>
              <th>Access Code</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredBuses.map((bus) => (
              <tr key={bus.id}>
                <td>{bus.busNo}</td>
                <td>{bus.busType}</td>
                <td>{bus.totalSeats}</td>
                <td>{bus.ownerName}</td>
                <td>{bus.ownerNIC}</td>
                <td>{bus.driverContact}</td>
                <td>
                  <span
                    className={`chip ${
                      bus.status === 'Active'
                        ? 'chip-green'
                        : bus.status === 'Delayed'
                        ? 'chip-amber'
                        : bus.status === 'Offline'
                        ? 'chip-red'
                        : 'chip-blue'
                    }`}
                  >
                    {bus.status || 'Idle'}
                  </span>
                </td>
                <td><span className="access-code">{bus.accessCode || '-'}</span></td>
                <td className="actions-cell">
                  <button type="button" onClick={() => handleEdit(bus)}>Edit</button>
                  <button type="button" onClick={() => handleDelete(bus.id, bus.busNo)}>Delete</button>
                </td>
              </tr>
            ))}
            {filteredBuses.length === 0 && (
              <tr>
                <td colSpan="9" className="empty-row">No buses match your filters.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
};

export default Buses;
