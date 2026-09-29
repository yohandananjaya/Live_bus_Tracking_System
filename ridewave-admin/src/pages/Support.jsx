import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, updateDoc, doc, where } from 'firebase/firestore';
import { db } from '../firebase';

const Support = () => {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState('');

  // Firebase එකෙන් Real-time Reports ගන්නවා
  useEffect(() => {
    const q = query(
      collection(db, 'admin_reports'),
      where('status', '==', 'pending') // විසඳපු නැති ඒවා විතරයි
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const reportsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data()
      }));
      // අලුත්ම ඒවා උඩට එන්න Sort කරනවා
      reportsData.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
      setAlerts(reportsData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // ප්‍රශ්නය විසඳුවාම Status එක Update කරනවා
  const handleResolve = async (alertId) => {
    try {
      await updateDoc(doc(db, 'admin_reports', alertId), {
        status: 'resolved',
        resolvedAt: new Date().toISOString()
      });
      setNotice(`Issue marked as resolved!`);
      setTimeout(() => setNotice(''), 3000);
    } catch (error) {
      console.error("Error resolving:", error);
    }
  };

  if (loading) {
    return (
      <section className="panel">
        <div className="alerts-head"><h2>System Reports & SOS</h2></div>
        <p className="loading-text">Loading real-time alerts...</p>
      </section>
    );
  }

  return (
    <section className="panel">
      <div className="alerts-head">
        <div>
          <h2>System Reports & SOS</h2>
          <p className="panel-copy">Review live complaints and issues from drivers and passengers.</p>
        </div>
        <span className="chip chip-red">{alerts.length} Pending</span>
      </div>

      {notice && <p className="form-notice success">{notice}</p>}

      <div className="alerts-list">
        {alerts.map((alert) => (
          <article key={alert.id} className="alert-ticket">
            <div className="alert-ticket-head">
              <div>
                <strong>Bus ID: {alert.busId || 'Unknown'}</strong>
                <p>Reported Issue</p>
              </div>
              <div className="alert-meta">
                <span className="chip chip-amber">Pending</span>
                <small>{alert.timestamp?.toDate().toLocaleString() || 'Just now'}</small>
              </div>
            </div>

            <p className="alert-passenger">
              <strong>Source:</strong> Driver App / System
            </p>
            <p className="alert-message" style={{ fontSize: '15px', color: '#d32f2f', fontWeight: 'bold' }}>
              {alert.issue}
            </p>

            <div className="alert-actions" style={{ marginTop: '15px' }}>
              <button type="button" className="action-btn" onClick={() => handleResolve(alert.id)}>
                Mark as Resolved
              </button>
            </div>
          </article>
        ))}
      </div>

      {alerts.length === 0 && (
        <div className="empty-alerts">
          <p>Great! All alerts are resolved right now.</p>
        </div>
      )}
    </section>
  );
};

export default Support;