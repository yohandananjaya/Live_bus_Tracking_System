import React, { useEffect, useMemo, useState, Fragment } from 'react';
import { collection, query, where, onSnapshot, doc, arrayRemove, writeBatch, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';

const Financials = () => {
  const [bookings, setBookings] = useState([]);
  const [refundRequests, setRefundRequests] = useState([]);
  const [payouts, setPayouts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [activeTab, setActiveTab] = useState('revenue');
  const [expandedBusId, setExpandedBusId] = useState(null);

  // Format date safely
  const formatDate = (dateValue) => {
    if (!dateValue) return 'N/A';
    if (dateValue.toDate) return dateValue.toDate().toLocaleDateString();
    if (typeof dateValue === 'string') return new Date(dateValue).toLocaleDateString();
    if (dateValue instanceof Date) return dateValue.toLocaleDateString();
    return 'Invalid Date';
  };

  function calculatePayouts(bookingsData) {
    const busMap = {};
    const COMMISSION_RATE = 0.25;

    bookingsData.forEach((booking) => {
      if (booking.payoutSettled) return; // Ignore settled bookings

      const busId = booking.busId;
      const travelDateStr = booking.travelDate || 'Unknown Date';

      if (!busMap[busId]) {
        busMap[busId] = {
          busId: busId,
          busNo: booking.busNo || booking.busName || busId,
          totalSeatsCount: 0,
          totalCollected: 0,
          commission: 0,
          due: 0,
          dates: {}
        };
      }
      
      const bus = busMap[busId];
      if (!bus.dates[travelDateStr]) {
        bus.dates[travelDateStr] = {
          travelDate: travelDateStr,
          totalCollected: 0,
          commission: 0,
          due: 0,
          bookedSeats: new Set(),
          bookingIds: [],
          isFinished: travelDateStr !== 'Unknown Date' && new Date(travelDateStr) < new Date(new Date().setHours(0,0,0,0))
        };
      }
      
      const dateEntry = bus.dates[travelDateStr];
      const commissionAmount = booking.totalPrice * COMMISSION_RATE;
      
      bus.totalCollected += booking.totalPrice;
      bus.commission += commissionAmount;
      bus.due += booking.totalPrice - commissionAmount;
      bus.totalSeatsCount += booking.seats.length;
      
      dateEntry.totalCollected += booking.totalPrice;
      dateEntry.commission += commissionAmount;
      dateEntry.due += booking.totalPrice - commissionAmount;
      booking.seats.forEach(seat => dateEntry.bookedSeats.add(seat));
      dateEntry.bookingIds.push(booking.id);
    });

    const payoutsArray = Object.values(busMap).map(bus => {
      const sortedDates = Object.values(bus.dates).sort((a, b) => new Date(a.travelDate) - new Date(b.travelDate));
      return {
        ...bus,
        dates: sortedDates
      };
    }).filter(bus => bus.due > 0);
    
    setPayouts(payoutsArray);
  }

  useEffect(() => {
    setLoading(true);
    setError('');

    try {
      const q = query(collection(db, 'bookings'), where('status', 'in', ['confirmed', 'completed']));
      const unsubscribe = onSnapshot(q, (snapshot) => {
        const bookingsData = snapshot.docs.map((doc) => ({
          id: doc.id,
          bookingRef: doc.data().bookingRef || `RW-${doc.id.substring(0, 6).toUpperCase()}`,
          busId: doc.data().busId || '',
          busNo: doc.data().busNo || '',
          busName: doc.data().busName || '',
          userId: doc.data().userId || '',
          seats: Array.isArray(doc.data().seats) ? doc.data().seats : [],
          totalPrice: parseFloat(doc.data().totalPrice) || 0,
          travelDate: doc.data().travelDate || '',
          status: doc.data().status || 'pending',
          timestamp: doc.data().timestamp || null,
          payoutSettled: doc.data().payoutSettled || false,
        }));
        setBookings(bookingsData);
        setLoading(false);
        calculatePayouts(bookingsData);
      });
      return () => unsubscribe();
    } catch (err) {
      console.error(err);
      setError('Error connecting to database.');
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    try {
      const q = query(collection(db, 'bookings'), where('status', '==', 'refund_requested'));
      const unsubscribe = onSnapshot(q, (snapshot) => {
        const refundsData = snapshot.docs.map((doc) => {
          const data = doc.data();
          const baseAmount = parseFloat(data.totalPrice) || 0;
          const adminFee = baseAmount * 0.05;
          const driverFee = baseAmount * 0.05;
          const refundAmount = baseAmount - adminFee - driverFee;

          return {
            id: doc.id,
            bookingRef: data.bookingRef || `RW-${doc.id.substring(0, 6).toUpperCase()}`,
            busId: data.busId || '',
            busNo: data.busNo || '',
            userId: data.userId || '',
            seats: Array.isArray(data.seats) ? data.seats : [],
            totalPrice: baseAmount,
            adminFee,
            driverFee,
            refundAmount,
            travelDate: data.travelDate || '',
            requestedAt: data.timestamp || null,
          };
        });
        setRefundRequests(refundsData);
      });
      return () => unsubscribe();
    } catch (err) {
      console.error(err);
    }
  }, []); 



  const totals = useMemo(() => {
    const revenue = bookings.reduce((sum, booking) => sum + booking.totalPrice, 0);
    const totalPayouts = payouts.reduce((sum, payout) => sum + payout.due, 0);
    const pendingRefunds = refundRequests.reduce((sum, req) => sum + req.refundAmount, 0);
    return { revenue, totalPayouts, pendingRefunds };
  }, [bookings, payouts, refundRequests]);

  const handleApproveRefund = async (refundId, busId, seats, driverFee) => {
    try {
      const batch = writeBatch(db);
      const bookingRef = doc(db, 'bookings', refundId);
      batch.update(bookingRef, {
        status: 'refunded',
        refundedAt: new Date().toISOString(),
      });

      const busRef = doc(db, 'buses', busId);
      batch.update(busRef, {
        bookedSeats: arrayRemove(...seats), // Firebase arrayRemove supports multiple elements
      });

      await addDoc(collection(db, 'payouts'), {
        busId,
        amountTransferred: driverFee,
        date: new Date().toISOString(),
        status: 'pending',
        type: 'refund_fee',
        refundId,
      });

      await batch.commit();
      setNotice(`Refund approved for ${refundId}. Driver fee added.`);
      setTimeout(() => setNotice(''), 3000);
    } catch (err) {
      console.error(err);
      setError('Failed to approve refund.');
    }
  };

  // 🔥 Settle Bug එක හැදුවා
  const handleSettle = async (busId, dateEntry) => {
    try {
      const batch = writeBatch(db);

      // Create payout record for driver app
      const payoutRef = doc(collection(db, 'payouts'));
      batch.set(payoutRef, {
        busId: busId,
        busNo: busId, // Can fallback to busId
        amountTransferred: dateEntry.due,
        date: serverTimestamp(),
        status: 'settled',
        type: 'commission_settlement',
        travelDate: dateEntry.travelDate
      });

      // Mark bookings as settled
      dateEntry.bookingIds.forEach((bookingId) => {
        const bookingRef = doc(db, 'bookings', bookingId);
        batch.update(bookingRef, { payoutSettled: true });
      });

      await batch.commit();

      setNotice(`Settled LKR ${dateEntry.due.toLocaleString()} for ${dateEntry.travelDate}`);
      setTimeout(() => setNotice(''), 3000);
    } catch (err) {
      console.error(err);
      setError('Failed to settle payout.');
    }
  };

  if (loading) {
    return (
      <section className="panel"><p className="loading-text">Loading financial data...</p></section>
    );
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>Financials & Payouts</h2>
          <p className="panel-copy">Track daily bookings, revenue, and driver payouts.</p>
        </div>
        <span className="chip chip-green">LKR {totals.revenue.toLocaleString()}</span>
      </div>

      {error && <p className="form-notice error">{error}</p>}
      {notice && <p className="form-notice success">{notice}</p>}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '1ch', marginBottom: '1.5rem', borderBottom: '1px solid #ddd' }}>
        <button onClick={() => setActiveTab('revenue')} style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer', padding: '0.5rem 1rem', borderBottom: activeTab === 'revenue' ? '2px solid #007bff' : 'none', color: activeTab === 'revenue' ? '#007bff' : '#666', fontWeight: activeTab === 'revenue' ? 'bold' : 'normal' }}>
          Revenue ({bookings.length})
        </button>
        <button onClick={() => setActiveTab('refunds')} style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer', padding: '0.5rem 1rem', borderBottom: activeTab === 'refunds' ? '2px solid #007bff' : 'none', color: activeTab === 'refunds' ? '#007bff' : '#666', fontWeight: activeTab === 'refunds' ? 'bold' : 'normal' }}>
          Refunds ({refundRequests.length})
        </button>
        <button onClick={() => setActiveTab('payouts')} style={{ backgroundColor: 'transparent', border: 'none', cursor: 'pointer', padding: '0.5rem 1rem', borderBottom: activeTab === 'payouts' ? '2px solid #007bff' : 'none', color: activeTab === 'payouts' ? '#007bff' : '#666', fontWeight: activeTab === 'payouts' ? 'bold' : 'normal' }}>
          Payouts
        </button>
      </div>

      {activeTab === 'revenue' && (
        <article className="panel">
          <div className="panel-head">
            <h3>All Confirmed Bookings</h3>
            <span className="chip">{bookings.length} Bookings</span>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Booking Ref</th>
                  <th>Bus ID</th>
                  <th>Travel Date</th>
                  <th>Seats</th>
                  <th>Amount (LKR)</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {bookings.length > 0 ? (
                  bookings.map((booking) => (
                    <tr key={booking.id}>
                      <td>{booking.bookingRef}</td>
                      <td>{booking.busNo}</td>
                      <td>{formatDate(booking.travelDate)}</td>
                      <td>{booking.seats.length > 0 ? booking.seats.join(', ') : 'N/A'}</td>
                      <td>{booking.totalPrice.toLocaleString()}</td>
                      <td>
                        <span className={`chip ${booking.status === 'completed' ? 'chip-green' : 'chip-blue'}`}>{booking.status}</span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan="6" className="empty-row">No confirmed bookings yet.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      )}

      {activeTab === 'refunds' && (
        <article className="panel">
          <div className="panel-head">
            <h3>Refund Requests</h3>
            <span className="chip chip-amber">{refundRequests.length} Pending</span>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Booking Ref</th>
                  <th>Bus No</th>
                  <th>Original Price</th>
                  <th>Admin Fee</th>
                  <th>Driver Fee</th>
                  <th>Refund Amount</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {refundRequests.length > 0 ? (
                  refundRequests.map((refund) => (
                    <tr key={refund.id}>
                      <td>{refund.bookingRef}</td>
                      <td>{refund.busNo}</td>
                      <td>{refund.totalPrice.toLocaleString()}</td>
                      <td>{refund.adminFee.toLocaleString()}</td>
                      <td>{refund.driverFee.toLocaleString()}</td>
                      <td className="highlight">{refund.refundAmount.toLocaleString()}</td>
                      <td>
                        <button onClick={() => handleApproveRefund(refund.id, refund.busId, refund.seats, refund.driverFee)} className="action-btn" style={{ padding: '0.5rem 1rem', fontSize: '0.9rem' }}>
                          Approve
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr><td colSpan="7" className="empty-row">No refund requests.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      )}

      {activeTab === 'payouts' && (
        <article className="panel">
          <div className="panel-head">
            <h3>Driver Payouts</h3>
            <span className="chip chip-blue">Due LKR {totals.totalPayouts.toLocaleString()}</span>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Bus No</th>
                  <th>Total Seats Booked</th>
                  <th>Total Collected</th>
                  <th>Commission (25%)</th>
                  <th>Due to Driver</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {payouts.length > 0 ? (
                  payouts.map((bus) => (
                    <React.Fragment key={bus.busId}>
                      <tr 
                        onClick={() => setExpandedBusId(expandedBusId === bus.busId ? null : bus.busId)}
                        style={{ cursor: 'pointer', backgroundColor: expandedBusId === bus.busId ? '#f8f9fa' : 'inherit' }}
                        title="Click to view trips for this bus"
                      >
                        <td><strong>{bus.busNo}</strong></td>
                        <td>{bus.totalSeatsCount}</td>
                        <td>{bus.totalCollected.toLocaleString()}</td>
                        <td>{bus.commission.toLocaleString()}</td>
                        <td className="highlight">{bus.due.toLocaleString()}</td>
                        <td>
                          {expandedBusId === bus.busId ? '▲ Hide Trips' : '▼ View Trips'}
                        </td>
                      </tr>
                      {expandedBusId === bus.busId && (
                        <tr>
                          <td colSpan="6" style={{ padding: '0', backgroundColor: '#fafafa', borderBottom: '2px solid #ddd' }}>
                            <div style={{ padding: '1rem', margin: '0.5rem', backgroundColor: 'white', borderRadius: '8px', boxShadow: '0 2px 4px rgba(0,0,0,0.05)' }}>
                              <h4 style={{ margin: '0 0 1rem 0', color: '#555' }}>Pending Trips for {bus.busNo}</h4>
                              <table style={{ margin: 0, width: '100%', border: '1px solid #eee' }}>
                                <thead>
                                  <tr style={{ backgroundColor: '#f1f3f5' }}>
                                    <th>Trip Date</th>
                                    <th>Seats Booked</th>
                                    <th>Collected</th>
                                    <th>Commission</th>
                                    <th>Due</th>
                                    <th>Action</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {bus.dates.map((dateEntry, idx) => (
                                    <tr key={idx}>
                                      <td>{formatDate(dateEntry.travelDate)}</td>
                                      <td style={{ maxWidth: '150px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} title={Array.from(dateEntry.bookedSeats).join(', ')}>
                                        {Array.from(dateEntry.bookedSeats).join(', ') || 'None'}
                                      </td>
                                      <td>{dateEntry.totalCollected.toLocaleString()}</td>
                                      <td>{dateEntry.commission.toLocaleString()}</td>
                                      <td className="highlight" style={{fontWeight: 'bold', color: '#16a34a'}}>{dateEntry.due.toLocaleString()}</td>
                                      <td>
                                        {dateEntry.isFinished ? (
                                          <button type="button" className="action-btn" onClick={(e) => { e.stopPropagation(); handleSettle(bus.busId, dateEntry); }} style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem' }}>
                                            Settle Funds
                                          </button>
                                        ) : (
                                          <span style={{ color: 'orange', fontSize: '0.8rem', fontWeight: 'bold' }}>Trip Not Finished</span>
                                        )}
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  ))
                ) : (
                  <tr><td colSpan="6" className="empty-row">No payouts due right now.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      )}

      <article className="panel info-box" style={{ marginTop: '2rem' }}>
        <h3>Financial Workflow</h3>
        <ul>
          <li><strong>Revenue:</strong> Only counts confirmed & completed bookings.</li>
          <li><strong>Refunds:</strong> 10% deduction (5% admin, 5% driver fee) when passengers cancel.</li>
          <li><strong>Payouts:</strong> Settling creates a record in the database which the Driver App reads immediately.</li>
        </ul>
      </article>
    </section>
  );
};

export default Financials;