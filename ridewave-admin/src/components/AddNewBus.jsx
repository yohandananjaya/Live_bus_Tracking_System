import { useState } from 'react';
import { addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase.js';

const initialForm = {
  busNo: '',
  busType: '',
  totalSeats: '',
  ownerName: '',
  ownerNIC: '',
  ownerContact: '',
};

const generateAccessCode = () => {
  const pool = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const code = Array.from({ length: 4 }, () => pool[Math.floor(Math.random() * pool.length)]).join('');
  return `RW-${code}`;
};

const AddNewBus = () => {
  const [form, setForm] = useState(initialForm);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [saving, setSaving] = useState(false);

  const handleChange = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError('');
    setNotice('');

    if (
      !form.busNo ||
      !form.busType ||
      !form.driverContact ||
      !form.totalSeats ||
      !form.ownerName ||
      !form.ownerNIC
    ) {
      setError('Please fill all required fields.');
      return;
    }

    if (!/^[A-Z]{2}-\d{4}$/i.test(form.busNo.trim())) {
      setError('Bus number must use format ND-4532.');
      return;
    }

    if (Number(form.totalSeats) <= 0) {
      setError('Total seats must be a positive number.');
      return;
    }

    const payload = {
      busNo: form.busNo.trim().toUpperCase(),
      busType: form.busType.trim(),
      totalSeats: Number(form.totalSeats),
      ownerName: form.ownerName.trim(),
      ownerNIC: form.ownerNIC.trim(),
      driverContact: form.driverContact.trim(),
      accessCode: generateAccessCode(),

      routeFrom: '',
      routeTo: '',
      stops: [],
      price: '0',
      status: 'Idle',
      totalRevenue: 0,
      bookedSeats: [],
      latitude: 0.0,
      longitude: 0.0,
      createdAt: serverTimestamp(),
    };

    setSaving(true);
    try {
      await addDoc(collection(db, 'buses'), payload);
      setNotice(`Bus added. Driver access code: ${payload.accessCode}`);
      setForm(initialForm);
    } catch (_error) {
      setError('Unable to save bus details. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <section className="w-full max-w-4xl rounded-2xl border border-slate-200 bg-white/80 p-6 shadow-xl backdrop-blur">
      <div className="mb-6">
        <h2 className="text-xl font-semibold text-slate-900">Add New Bus</h2>
        <p className="text-sm text-slate-500">Register the bus, owner, and generate a driver access code.</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-500">Bus Details</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <label className="grid gap-1 text-sm font-medium text-slate-700">
              Bus Number
              <input
                type="text"
                placeholder="ND-4532"
                value={form.busNo}
                onChange={(event) => handleChange('busNo', event.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-100"
                required
              />
            </label>
            <label className="grid gap-1 text-sm font-medium text-slate-700">
              Bus Type / Model
              <input
                type="text"
                placeholder="Normal - Leyland"
                value={form.busType}
                onChange={(event) => handleChange('busType', event.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-100"
                required
              />
            </label>
            <label className="grid gap-1 text-sm font-medium text-slate-700">
              Total Seats
              <input
                type="number"
                min="1"
                placeholder="54"
                value={form.totalSeats}
                onChange={(event) => handleChange('totalSeats', event.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-100"
                required
              />
            </label>
          </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-500">Owner Details</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <label className="grid gap-1 text-sm font-medium text-slate-700">
              Owner Name
              <input
                type="text"
                placeholder="Nimal Kumara"
                value={form.ownerName}
                onChange={(event) => handleChange('ownerName', event.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-100"
                required
              />
            </label>
            <label className="grid gap-1 text-sm font-medium text-slate-700">
              Owner NIC / ID Number
              <input
                type="text"
                placeholder="198512345678"
                value={form.ownerNIC}
                onChange={(event) => handleChange('ownerNIC', event.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-100"
                required
              />
            </label>
            <label className="grid gap-1 text-sm font-medium text-slate-700">
              Driver/Contact Number
              <input
                type="text"
                placeholder="0712345678"
                value={form.driverContact}
                onChange={(event) => handleChange('driverContact', event.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-slate-900 focus:border-cyan-400 focus:outline-none focus:ring-2 focus:ring-cyan-100"
                required
              />
            </label>
          </div>
        </section>

        {error && <p className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm font-semibold text-red-700">{error}</p>}
        {notice && <p className="rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm font-semibold text-emerald-700">{notice}</p>}

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs text-slate-500">
            Access code will be auto-generated when you save.
          </p>
          <button
            type="submit"
            disabled={saving}
            className="rounded-xl border border-cyan-500 bg-cyan-500 px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-cyan-600 disabled:cursor-not-allowed disabled:opacity-70"
          >
            {saving ? 'Saving...' : 'Generate Code & Save'}
          </button>
        </div>
      </form>
    </section>
  );
};

export default AddNewBus;

