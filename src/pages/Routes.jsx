import { useMemo, useState } from 'react';

const initialRoutes = [
  {
    id: 'R-101',
    name: 'Morning Express',
    busNo: 'BUS-014',
    path: 'Depot -> Main Street -> Tech Park -> Central Terminal',
    status: 'Active',
  },
  {
    id: 'R-102',
    name: 'School Connector',
    busNo: 'BUS-031',
    path: 'West End -> Cedar Avenue -> North High -> River Point',
    status: 'Active',
  },
  {
    id: 'R-103',
    name: 'Night Loop',
    busNo: 'BUS-046',
    path: 'Terminal -> Harbor Lane -> Stadium -> Terminal',
    status: 'Paused',
  },
];

const RoutesPage = () => {
  const [routes, setRoutes] = useState(initialRoutes);
  const [editingId, setEditingId] = useState(null);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const [draft, setDraft] = useState({
    id: '',
    name: '',
    busNo: '',
    path: '',
    status: 'Active',
  });

  const title = useMemo(
    () => (editingId ? `Edit Route ${editingId}` : 'Add New Route'),
    [editingId]
  );

  const resetDraft = () => {
    setDraft({ id: '', name: '', busNo: '', path: '', status: 'Active' });
    setEditingId(null);
    setError('');
  };

  const handleChange = (key, value) => {
    setDraft((current) => ({ ...current, [key]: value }));
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    setNotice('');
    setError('');

    if (!draft.id || !draft.name || !draft.busNo || !draft.path) {
      setError('Please fill all route fields.');
      return;
    }

    if (!/^R-\d{3}$/i.test(draft.id.trim())) {
      setError('Route ID must use format R-101.');
      return;
    }

    if (!/^BUS-\d{3}$/i.test(draft.busNo.trim())) {
      setError('Bus number must use format BUS-014.');
      return;
    }

    const payload = {
      id: draft.id.trim().toUpperCase(),
      name: draft.name.trim(),
      busNo: draft.busNo.trim().toUpperCase(),
      path: draft.path.trim(),
      status: draft.status,
    };

    if (editingId) {
      setRoutes((current) => current.map((route) => (route.id === editingId ? payload : route)));
      setNotice(`${payload.id} updated successfully.`);
      resetDraft();
      return;
    }

    const exists = routes.some((route) => route.id.toLowerCase() === payload.id.toLowerCase());
    if (exists) {
      setError('This route ID already exists.');
      return;
    }

    setRoutes((current) => [...current, payload]);
    setNotice(`${payload.id} added successfully.`);
    resetDraft();
  };

  const handleEdit = (route) => {
    setEditingId(route.id);
    setDraft(route);
    setNotice('');
    setError('');
  };

  const handleDelete = (routeId) => {
    setRoutes((current) => current.filter((route) => route.id !== routeId));
    if (editingId === routeId) resetDraft();
    setNotice(`${routeId} deleted.`);
  };

  return (
    <section className="panel">
      <div className="routes-header">
        <div>
          <h2>Routes Management</h2>
          <p className="panel-copy">View existing routes and manage add, edit, and delete actions.</p>
        </div>
        <span className="chip chip-blue">{routes.length} Routes</span>
      </div>

      <form className="form-panel" onSubmit={handleSubmit}>
        <h3 className="routes-form-title">{title}</h3>

        <div className="routes-form-grid">
          <label className="form-field">
            <span>Route ID</span>
            <input
              type="text"
              placeholder="R-104"
              value={draft.id}
              onChange={(event) => handleChange('id', event.target.value)}
              required
            />
          </label>

          <label className="form-field">
            <span>Route Name</span>
            <input
              type="text"
              placeholder="City Center Line"
              value={draft.name}
              onChange={(event) => handleChange('name', event.target.value)}
              required
            />
          </label>

          <label className="form-field">
            <span>Bus Number</span>
            <input
              type="text"
              placeholder="BUS-055"
              value={draft.busNo}
              onChange={(event) => handleChange('busNo', event.target.value)}
              required
            />
          </label>

          <label className="form-field">
            <span>Status</span>
            <select value={draft.status} onChange={(event) => handleChange('status', event.target.value)}>
              <option>Active</option>
              <option>Paused</option>
              <option>Completed</option>
            </select>
          </label>
        </div>

        <label className="form-field">
          <span>Route Path</span>
          <input
            type="text"
            placeholder="Stop A -> Stop B -> Stop C -> Stop D"
            value={draft.path}
            onChange={(event) => handleChange('path', event.target.value)}
            required
          />
        </label>

        {error && <p className="form-notice error">{error}</p>}
        {notice && <p className="form-notice success">{notice}</p>}

        <div className="form-actions">
          <button type="button" className="ghost-btn" onClick={resetDraft}>
            Clear
          </button>
          <button type="submit" className="action-btn">
            {editingId ? 'Update Route' : 'Add Route'}
          </button>
        </div>
      </form>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Route ID</th>
              <th>Route Name</th>
              <th>Bus Number</th>
              <th>Path</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {routes.map((route) => (
              <tr key={route.id}>
                <td>{route.id}</td>
                <td>{route.name}</td>
                <td>{route.busNo}</td>
                <td>{route.path}</td>
                <td>
                  <span
                    className={`chip ${
                      route.status === 'Active'
                        ? 'chip-green'
                        : route.status === 'Paused'
                        ? 'chip-amber'
                        : 'chip-red'
                    }`}
                  >
                    {route.status}
                  </span>
                </td>
                <td className="actions-cell">
                  <button type="button" onClick={() => handleEdit(route)}>
                    Edit
                  </button>
                  <button type="button" onClick={() => handleDelete(route.id)}>
                    Delete
                  </button>
                </td>
              </tr>
            ))}
            {routes.length === 0 && (
              <tr>
                <td className="empty-row" colSpan="6">
                  No routes available. Add a new route to start.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
};

export default RoutesPage;
