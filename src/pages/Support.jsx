import { useState } from 'react';

const passengerReports = [
  {
    id: 'RS-101',
    busNo: 'ND-4532',
    route: 'Colombo -> Kandy',
    message: 'Driver skipped the Kegalle stop without notice.',
    severity: 'High',
    passenger: 'N. Silva',
    time: '6m ago',
    type: 'Report',
  },
  {
    id: 'SOS-204',
    busNo: 'ND-6711',
    route: 'Negombo -> Colombo',
    message: 'Passenger collapsed near seat 14. Needs medical support.',
    severity: 'Critical',
    passenger: 'K. Perera',
    time: '2m ago',
    type: 'SOS',
  },
];

const driverReports = [
  {
    id: 'SOS-301',
    busNo: 'ND-8888',
    route: 'Galle -> Matara',
    message: 'Brake warning light on. Stopping at next safe point.',
    severity: 'High',
    driver: 'T. Jayasuriya',
    time: '9m ago',
    type: 'SOS',
  },
  {
    id: 'RS-412',
    busNo: 'ND-4532',
    route: 'Colombo -> Kandy',
    message: 'Traffic blocked near Kadawatha interchange. Need reroute guidance.',
    severity: 'Medium',
    driver: 'R. Mendis',
    time: '12m ago',
    type: 'Report',
  },
];

const authorities = [
  { id: 'transport', label: 'Transport Control' },
  { id: 'police', label: 'Police' },
  { id: 'emergency', label: 'Emergency Service' },
];

const Support = () => {
  const [activeTab, setActiveTab] = useState('passenger');
  const [alerts, setAlerts] = useState(passengerReports);
  const [replyDrafts, setReplyDrafts] = useState({});
  const [replies, setReplies] = useState({});
  const [authorityLogs, setAuthorityLogs] = useState({});
  const [notice, setNotice] = useState('');

  const handleTabChange = (tab) => {
    setActiveTab(tab);
    setAlerts(tab === 'passenger' ? passengerReports : driverReports);
    setNotice('');
  };

  const handleReplyChange = (alertId, value) => {
    setReplyDrafts((current) => ({ ...current, [alertId]: value }));
  };

  const handleSendReply = (alertId) => {
    const text = (replyDrafts[alertId] || '').trim();
    if (!text) return;

    setReplies((current) => ({ ...current, [alertId]: text }));
    setReplyDrafts((current) => ({ ...current, [alertId]: '' }));
    setNotice(`Reply sent for ${alertId}.`);
  };

  const handleConnectAuthority = (alertId, authority) => {
    setAuthorityLogs((current) => ({
      ...current,
      [alertId]: `Connected to ${authority} at ${new Date().toLocaleTimeString()}`,
    }));
    setNotice(`${alertId} escalated to ${authority}.`);
  };

  const handleResolve = (alertId) => {
    setAlerts((current) => current.filter((alert) => alert.id !== alertId));
    setNotice(`${alertId} marked as resolved.`);
  };

  return (
    <section className="panel">
      <div className="alerts-head">
        <div>
          <div style={{ display: 'flex', gap: '1ch', alignItems: 'center' }}>
            <button
              type="button"
              style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer' }}
              onClick={() => handleTabChange('passenger')}
            >
              <h2 className={activeTab === 'passenger' ? 'tab tab-active' : 'tab'}>Passenger Reports</h2>
            </button>
            <button
              type="button"
              style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer' }}
              onClick={() => handleTabChange('driver')}
            >
              <h2 className={activeTab === 'driver' ? 'tab tab-active' : 'tab'}>Driver SOS</h2>
            </button>
          </div>
          <p className="panel-copy">Review complaints, SOS alerts, and resolve incidents quickly.</p>
        </div>
        <span className="chip chip-red">{alerts.length} Open</span>
      </div>

      {notice && <p className="form-notice success">{notice}</p>}

      <div className="alerts-list">
        {alerts.map((alert) => (
          <article key={alert.id} className="alert-ticket">
            <div className="alert-ticket-head">
              <div>
                <strong>{alert.id}</strong>
                <p>{alert.busNo} | {alert.route}</p>
              </div>
              <div className="alert-meta">
                <span
                  className={`chip ${
                    alert.severity === 'Critical'
                      ? 'chip-red'
                      : alert.severity === 'High'
                      ? 'chip-amber'
                      : 'chip-blue'
                  }`}
                >
                  {alert.type}
                </span>
                <small>{alert.time}</small>
              </div>
            </div>

            <p className="alert-passenger">
              <strong>{activeTab === 'passenger' ? 'Passenger' : 'Driver'}:</strong>{' '}
              {activeTab === 'passenger' ? alert.passenger : alert.driver}
            </p>
            <p className="alert-message">{alert.message}</p>

            <div className="alert-reply-row">
              <input
                type="text"
                placeholder="Type a response..."
                value={replyDrafts[alert.id] || ''}
                onChange={(event) => handleReplyChange(alert.id, event.target.value)}
              />
              <button type="button" className="action-btn" onClick={() => handleSendReply(alert.id)}>
                Send Reply
              </button>
            </div>

            {replies[alert.id] && (
              <p className="alert-reply-preview"><strong>Last reply:</strong> {replies[alert.id]}</p>
            )}

            <div className="authority-row">
              <span>Connect with authority:</span>
              <div className="authority-buttons">
                {authorities.map((authority) => (
                  <button
                    key={authority.id}
                    type="button"
                    className="ghost-btn"
                    onClick={() => handleConnectAuthority(alert.id, authority.label)}
                  >
                    {authority.label}
                  </button>
                ))}
              </div>
            </div>

            {authorityLogs[alert.id] && (
              <p className="authority-log">{authorityLogs[alert.id]}</p>
            )}

            <div className="alert-actions">
              <button type="button" className="ghost-btn" onClick={() => handleResolve(alert.id)}>
                Mark as Resolved
              </button>
            </div>
          </article>
        ))}
      </div>

      {alerts.length === 0 && (
        <div className="empty-alerts">
          <p>All alerts are resolved.</p>
        </div>
      )}
    </section>
  );
};

export default Support;
