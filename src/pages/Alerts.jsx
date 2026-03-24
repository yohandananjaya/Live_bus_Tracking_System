import { useState } from 'react';

const initialAlerts = [
  {
    id: 'AL-001',
    busNo: 'BUS-022',
    route: 'Airport Express',
    message: 'Driver is skipping Stop 5 and passengers are waiting.',
    severity: 'High',
    passenger: 'N. Silva',
    time: '3m ago',
  },
  {
    id: 'AL-002',
    busNo: 'BUS-031',
    route: 'Hilltop Connector',
    message: 'Very crowded, please send another bus.',
    severity: 'Medium',
    passenger: 'K. Perera',
    time: '7m ago',
  },
  {
    id: 'AL-003',
    busNo: 'BUS-046',
    route: 'Central Circle',
    message: 'A suspicious package was seen near rear seat.',
    severity: 'Critical',
    passenger: 'A. Fernando',
    time: '1m ago',
  },
];

const initialDriverAlerts = [
  {
    id: 'AL-001',
    busNo: 'BUS-022',
    route: 'Airport Express',
    message: 'Heavy traffic newr the airport entrance. This turn will take time it should be.',
    severity: 'High',
    driver: 'N. Silva',
    time: '20m ago',
  },
  {
    id: 'AL-002',
    busNo: 'BUS-031',
    route: 'Hilltop Connector',
    message: 'Bus has been surrounded with flood. Water has entered to the engine and bus has stopped',
    severity: 'Medium',
    driver: 'K. Perera',
    time: '17m ago',
  },
  {
    id: 'AL-003',
    busNo: 'BUS-046',
    route: 'Central Circle',
    message: 'A picketing is going around blocking the road. Give another route to avoid them.',
    severity: 'Critical',
    driver: 'A. Fernando',
    time: '10m ago',
  },
];



const authorities = [
  { id: 'transport', label: 'Transport Control' },
  { id: 'police', label: 'Police' },
  { id: 'emergency', label: 'Emergency Service' },
];

const AlertsPage = () => {
  const [alerts, setAlerts] = useState(initialAlerts);
  const [activeTab, setActiveTab] = useState('passenger');
  const [replyDrafts, setReplyDrafts] = useState({});
  const [replies, setReplies] = useState({});
  const [authorityLogs, setAuthorityLogs] = useState({});
  const [notice, setNotice] = useState('');
  
  const alertTypePassenger=()=>{
    setAlerts(initialAlerts);
    setActiveTab('passenger');
  }

  const alertTypeDriver=()=>{
    setAlerts(initialDriverAlerts);
    setActiveTab('driver');
  }


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
          <div style={{display:'flex', gap:'1ch', alignItems:'center'}}>
          <button style={{backgroundColor:"transparent",border:"none",cursor:"pointer"}} onClick={alertTypePassenger}><h2 className={activeTab === 'passenger'?'tab tab-active':'tab'}>Passenger Alerts</h2></button>
          <button style={{backgroundColor:"transparent",border:"none", cursor:"pointer"}} onClick={alertTypeDriver}><h2 className={activeTab==='driver'?'tab tab-active':'tab'}>Driver Alerts</h2></button>
          </div>
          <p className="panel-copy">Review alerts, send individual replies, and escalate to authorities when needed.</p>
        </div>
        <span className="chip chip-red">{alerts.length} Open Alerts</span>
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
                  {alert.severity}
                </span>
                <small>{alert.time}</small>
              </div>
            </div>

            <p className="alert-passenger"><strong>Passenger:</strong> {alert.passenger}</p>
            <p className="alert-message">{alert.message}</p>

            <div className="alert-reply-row">
              <input
                type="text"
                placeholder="Type a reply to passenger..."
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

export default AlertsPage;
