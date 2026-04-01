import { useEffect, useState } from 'react';
import { collection, query, where, onSnapshot, updateDoc, doc } from 'firebase/firestore';
import { db } from '../firebase';

const authorities = [
  { id: 'transport', label: 'Transport Control' },
  { id: 'police', label: 'Police' },
  { id: 'emergency', label: 'Emergency Service' },
];

const AlertsPage = () => {
  const [reports, setReports] = useState([]);
  const [activeTab, setActiveTab] = useState('SOS');
  const [replyDrafts, setReplyDrafts] = useState({});
  const [replies, setReplies] = useState({});
  const [authorityLogs, setAuthorityLogs] = useState({});
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  // Helper to format timestamp
  const formatTime = (timestamp) => {
    if (!timestamp) return 'N/A';
    if (timestamp.toDate) {
      return timestamp.toDate().toLocaleString();
    }
    if (typeof timestamp === 'string') {
      return new Date(timestamp).toLocaleString();
    }
    return 'Unknown time';
  };

  // Fetch reports from Firestore based on active tab
  useEffect(() => {
    setLoading(true);
    setError('');

    try {
      const q = query(
        collection(db, 'reports'),
        where('type', '==', activeTab),
        where('status', '==', 'Open')
      );

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const reportsData = snapshot.docs.map((doc) => ({
            id: doc.id,
            busId: doc.data().busId || '',
            type: doc.data().type || '',
            message: doc.data().message || '',
            severity: doc.data().severity || 'Medium',
            senderType: doc.data().senderType || 'Passenger',
            senderName: doc.data().senderName || 'Anonymous',
            timestamp: doc.data().timestamp || null,
            status: doc.data().status || 'Open',
          }));
          setReports(reportsData);
          setLoading(false);
        },
        (err) => {
          console.error('Error fetching reports:', err);
          setError('Failed to load reports. Please try again.');
          setLoading(false);
        }
      );

      return () => unsubscribe();
    } catch (err) {
      console.error('Error setting up reports listener:', err);
      setError('Error connecting to database.');
      setLoading(false);
    }
  }, [activeTab]);


  const handleReplyChange = (reportId, value) => {
    setReplyDrafts((current) => ({ ...current, [reportId]: value }));
  };

  const handleSendReply = (reportId) => {
    const text = (replyDrafts[reportId] || '').trim();
    if (!text) return;

    setReplies((current) => ({ ...current, [reportId]: text }));
    setReplyDrafts((current) => ({ ...current, [reportId]: '' }));
    setNotice(`Reply sent for ${reportId}.`);
    setTimeout(() => setNotice(''), 3000);
  };

  const handleConnectAuthority = (reportId, authority) => {
    setAuthorityLogs((current) => ({
      ...current,
      [reportId]: `Connected to ${authority} at ${new Date().toLocaleTimeString()}`,
    }));
    setNotice(`${reportId} escalated to ${authority}.`);
    setTimeout(() => setNotice(''), 3000);
  };

  const handleResolve = async (reportId) => {
    try {
      const reportRef = doc(db, 'reports', reportId);
      await updateDoc(reportRef, {
        status: 'Resolved',
        resolvedAt: new Date().toISOString(),
      });
      setNotice(`${reportId} marked as resolved.`);
      setTimeout(() => setNotice(''), 3000);
    } catch (err) {
      console.error('Error resolving report:', err);
      setError('Failed to resolve report. Please try again.');
    }
  };

  const severityClass = (severity) => {
    switch (severity) {
      case 'Critical':
        return 'chip-red';
      case 'High':
        return 'chip-amber';
      default:
        return 'chip-blue';
    }
  };

  if (loading && reports.length === 0) {
    return (
      <section className="panel">
        <div className="alerts-head">
          <h2>Alerts & Reports</h2>
        </div>
        <p className="loading-text">Loading reports...</p>
      </section>
    );
  }

  return (
    <section className="panel">
      <div className="alerts-head">
        <div>
          <div style={{ display: 'flex', gap: '1ch', alignItems: 'center' }}>
            <button
              style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer' }}
              onClick={() => setActiveTab('SOS')}
            >
              <h2 className={activeTab === 'SOS' ? 'tab tab-active' : 'tab'}>SOS Calls</h2>
            </button>
            <button
              style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer' }}
              onClick={() => setActiveTab('Report')}
            >
              <h2 className={activeTab === 'Report' ? 'tab tab-active' : 'tab'}>Reports</h2>
            </button>
          </div>
          <p className="panel-copy">Review alerts, send replies, and escalate to authorities when needed.</p>
        </div>
        <span className="chip chip-red">{reports.length} Open</span>
      </div>

      {error && <p className="form-notice error">{error}</p>}
      {notice && <p className="form-notice success">{notice}</p>}

      <div className="alerts-list">
        {reports.map((report) => (
          <article key={report.id} className="alert-ticket">
            <div className="alert-ticket-head">
              <div>
                <strong>{report.id}</strong>
                <p>{report.type} | Bus: {report.busId}</p>
              </div>
              <div className="alert-meta">
                <span className={`chip ${severityClass(report.severity)}`}>
                  {report.severity}
                </span>
                <small>{formatTime(report.timestamp)}</small>
              </div>
            </div>

            <p className="alert-passenger">
              <strong>From {report.senderType}:</strong> {report.senderName}
            </p>
            <p className="alert-message">{report.message}</p>

            <div className="alert-reply-row">
              <input
                type="text"
                placeholder="Type a reply..."
                value={replyDrafts[report.id] || ''}
                onChange={(event) => handleReplyChange(report.id, event.target.value)}
              />
              <button type="button" className="action-btn" onClick={() => handleSendReply(report.id)}>
                Send Reply
              </button>
            </div>

            {replies[report.id] && (
              <p className="alert-reply-preview">
                <strong>Last reply:</strong> {replies[report.id]}
              </p>
            )}

            <div className="authority-row">
              <span>Connect with authority:</span>
              <div className="authority-buttons">
                {authorities.map((authority) => (
                  <button
                    key={authority.id}
                    type="button"
                    className="ghost-btn"
                    onClick={() => handleConnectAuthority(report.id, authority.label)}
                  >
                    {authority.label}
                  </button>
                ))}
              </div>
            </div>

            {authorityLogs[report.id] && (
              <p className="authority-log">{authorityLogs[report.id]}</p>
            )}

            <div className="alert-actions">
              <button type="button" className="ghost-btn" onClick={() => handleResolve(report.id)}>
                Mark as Resolved
              </button>
            </div>
          </article>
        ))}
      </div>

      {reports.length === 0 && (
        <div className="empty-alerts">
          <p>All {activeTab === 'SOS' ? 'SOS calls' : 'reports'} are resolved.</p>
        </div>
      )}
    </section>
  );
};

export default AlertsPage;
