import { useEffect, useMemo, useState } from 'react';
import { collection, query, where, onSnapshot, updateDoc, doc, arrayRemove, writeBatch, addDoc } from 'firebase/firestore';
import { db } from '../firebase';

const Financials = () => {
  const [bookings, setBookings] = useState([]);
  const [refundRequests, setRefundRequests] = useState([]);
  const [payouts, setPayouts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [activeTab, setActiveTab] = useState('revenue');

  // Format date safely
  const formatDate = (dateValue) => {
    if (!dateValue) return 'N/A';
    if (dateValue.toDate) {
      return dateValue.toDate().toLocaleDateString();
    }
    if (typeof dateValue === 'string') {
      return new Date(dateValue).toLocaleDateString();
    }
    if (dateValue instanceof Date) {
      return dateValue.toLocaleDateString();
    }
    return 'Invalid Date';
  };

  // Fetch bookings from Firestore in real-time
  useEffect(() => {
    setLoading(true);
    setError('');

    try {
      const q = query(
        collection(db, 'bookings'),
        where('status', 'in', ['confirmed', 'completed'])
      );

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const bookingsData = snapshot.docs.map((doc) => ({
            id: doc.id,
            bookingRef: doc.data().bookingRef || `RW-${doc.id.substring(0, 6).toUpperCase()}`,
            busId: doc.data().busId || '',
            busNo: doc.data().busNo || '',
            userId: doc.data().userId || '',
            seats: Array.isArray(doc.data().seats) ? doc.data().seats : [],
            totalPrice: parseFloat(doc.data().totalPrice) || 0,
            travelDate: doc.data().travelDate || '',
            status: doc.data().status || 'pending',
            timestamp: doc.data().timestamp || null,
          }));

          setBookings(bookingsData);
          setLoading(false);
          calculatePayouts(bookingsData);
        },
        (err) => {
          console.error('Error fetching bookings:', err);
          setError('Failed to load bookings. Please try again.');
          setLoading(false);
        }
      );

      return () => unsubscribe();
    } catch (err) {
      console.error('Error setting up bookings listener:', err);
      setError('Error connecting to database.');
      setLoading(false);
    }
  }, []);

  // Fetch refund requests
  useEffect(() => {
    try {
      const q = query(
        collection(db, 'bookings'),
        where('status', '==', 'refund_requested')
      );

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
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
        },
        (err) => {
          console.error('Error fetching refund requests:', err);
        }
      );

      return () => unsubscribe();
    } catch (err) {
      console.error('Error setting up refund listener:', err);
    }
  }, []);

  // Calculate payouts from bookings
  const calculatePayouts = (bookingsData) => {
    const payoutMap = {};
    const COMMISSION_RATE = 0.25;

    bookingsData.forEach((booking) => {
      if (!payoutMap[booking.busId]) {
        payoutMap[booking.busId] = {
          busId: booking.busId,
          busNo: booking.busNo,
          totalCollected: 0,
          commission: 0,
          due: 0,
          status: 'Pending',
        };
      }

      payoutMap[booking.busId].totalCollected += booking.totalPrice;
      const commissionAmount = booking.totalPrice * COMMISSION_RATE;
      payoutMap[booking.busId].commission += commissionAmount;
      payoutMap[booking.busId].due += booking.totalPrice - commissionAmount;
    });

    const payoutsArray = Object.entries(payoutMap).map(([_, payout], index) => ({
      id: `PO-${String(index + 1).padStart(4, '0')}`,
      ...payout,
    }));

    setPayouts(payoutsArray);
  };

  // Calculate totals
  const totals = useMemo(() => {
    const revenue = bookings.reduce((sum, booking) => sum + booking.totalPrice, 0);
    const totalPayouts = payouts.reduce((sum, payout) => sum + payout.due, 0);
    const pendingRefunds = refundRequests.reduce((sum, req) => sum + req.refundAmount, 0);
    return { revenue, totalPayouts, pendingRefunds };
  }, [bookings, payouts, refundRequests]);

  const handleApproveRefund = async (refundId, busId, seats, driverFee) => {
    try {
      const batch = writeBatch(db);

      // Update booking status to refunded
      const bookingRef = doc(db, 'bookings', refundId);
      batch.update(bookingRef, {
        status: 'refunded',
        refundedAt: new Date().toISOString(),
      });

      // Remove seats from bus bookedSeats array
      const busRef = doc(db, 'buses', busId);
      seats.forEach((seat) => {
        batch.update(busRef, {
          bookedSeats: arrayRemove(seat),
        });
      });

      // Add driver fee to payouts (separate collection)
      await addDoc(collection(db, 'payouts'), {
        busId,
        amountTransferred: driverFee,
        date: new Date().toISOString(),
        status: 'pending',
        type: 'refund_fee',
        refundId,
      });

      await batch.commit();

      setNotice(`Refund approved for ${refundId}. Driver fee: LKR ${driverFee.toLocaleString()}`);
      setTimeout(() => setNotice(''), 3000);
    } catch (err) {
      console.error('Error approving refund:', err);
      setError('Failed to approve refund. Please try again.');
    }
  };

  const handleSettle = async (payoutId) => {
    try {
      const payout = payouts.find((p) => p.id === payoutId);
      if (!payout) return;

      // Create a settlement record
      await addDoc(collection(db, 'payouts'), {
        busId: payout.busId,
        busNo: payout.busNo,
        amountTransferred: payout.due,
        date: new Date().toISOString(),
        status: 'settled',
        type: 'commission',
      });

      setPayouts((current) =>
        current.map((p) =>
          p.id === payoutId ? { ...p, status: 'Settled' } : p
        )
      );
      setNotice(`${payoutId} marked as settled.`);
      setTimeout(() => setNotice(''), 3000);
    } catch (err) {
      console.error('Error settling payout:', err);
      setError('Failed to settle payout.');
    }
  };

  if (loading) {
    return (
      <section className="panel">
        <div className="panel-head">
          <h2>Financials & Payouts</h2>
        </div>
        <p className="loading-text">Loading financial data...</p>
      </section>
    );
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>Financials & Payouts</h2>
          <p className="panel-copy">Track bookings, revenue, refunds, and driver payouts.</p>
        </div>
        <span className="chip chip-green">LKR {totals.revenue.toLocaleString()}</span>
      </div>

      {error && <p className="form-notice error">{error}</p>}
      {notice && <p className="form-notice success">{notice}</p>}

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '1ch', marginBottom: '1.5rem', borderBottom: '1px solid #ddd' }}>
        <button
          onClick={() => setActiveTab('revenue')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            cursor: 'pointer',
            padding: '0.5rem 1rem',
            borderBottom: activeTab === 'revenue' ? '2px solid #007bff' : 'none',
            color: activeTab === 'revenue' ? '#007bff' : '#666',
            fontWeight: activeTab === 'revenue' ? 'bold' : 'normal',
          }}
        >
          💰 Revenue ({bookings.length})
        </button>
        <button
          onClick={() => setActiveTab('refunds')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            cursor: 'pointer',
            padding: '0.5rem 1rem',
            borderBottom: activeTab === 'refunds' ? '2px solid #007bff' : 'none',
            color: activeTab === 'refunds' ? '#007bff' : '#666',
            fontWeight: activeTab === 'refunds' ? 'bold' : 'normal',
          }}
        >
          🔄 Refunds ({refundRequests.length})
        </button>
        <button
          onClick={() => setActiveTab('payouts')}
          style={{
            backgroundColor: 'transparent',
            border: 'none',
            cursor: 'pointer',
            padding: '0.5rem 1rem',
            borderBottom: activeTab === 'payouts' ? '2px solid #007bff' : 'none',
            color: activeTab === 'payouts' ? '#007bff' : '#666',
            fontWeight: activeTab === 'payouts' ? 'bold' : 'normal',
          }}
        >
          🤑 Payouts
        </button>
      </div>

      {/* Revenue Tab */}
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
                        <span className={`chip ${booking.status === 'completed' ? 'chip-green' : 'chip-blue'}`}>
                          {booking.status}
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="6" className="empty-row">No bookings yet.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      )}

      {/* Refunds Tab */}
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
                  <th>Bus ID</th>
                  <th>Original Price</th>
                  <th>Admin Fee (5%)</th>
                  <th>Driver Fee (5%)</th>
                  <th>Refund Amount</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {refundRequests.length > 0 ? (
                  refundRequests.map((refund) => (
                    <tr key={refund.id}>
                      <td>{refund.bookingRef}</td>
                      <td>{refund.busId}</td>
                      <td>{refund.totalPrice.toLocaleString()}</td>
                      <td>{refund.adminFee.toLocaleString()}</td>
                      <td>{refund.driverFee.toLocaleString()}</td>
                      <td className="highlight">{refund.refundAmount.toLocaleString()}</td>
                      <td>
                        <button
                          onClick={() => handleApproveRefund(refund.id, refund.busId, refund.seats, refund.driverFee)}
                          className="action-btn"
                          style={{ padding: '0.5rem 1rem', fontSize: '0.9rem' }}
                        >
                          Approve
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="7" className="empty-row">No refund requests.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      )}

      {/* Payouts Tab */}
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
                  <th>Payout ID</th>
                  <th>Bus ID</th>
                  <th>Bus No</th>
                  <th>Total Collected</th>
                  <th>Commission (25%)</th>
                  <th>Due</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {payouts.length > 0 ? (
                  payouts.map((payout) => (
                    <tr key={payout.id}>
                      <td>{payout.id}</td>
                      <td>{payout.busId}</td>
                      <td>{payout.busNo}</td>
                      <td>{payout.totalCollected.toLocaleString()}</td>
                      <td>{payout.commission.toLocaleString()}</td>
                      <td className="highlight">{payout.due.toLocaleString()}</td>
                      <td>
                        <span className={`chip ${payout.status === 'Settled' ? 'chip-green' : 'chip-amber'}`}>
                          {payout.status}
                        </span>
                      </td>
                      <td>
                        <button
                          className="ghost-btn"
                          disabled={payout.status === 'Settled'}
                          onClick={() => handleSettle(payout.id)}
                          style={{ padding: '0.5rem 1rem', fontSize: '0.9rem' }}
                        >
                          Settle
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="8" className="empty-row">No payouts due.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      )}

      <article className="panel info-box" style={{ marginTop: '2rem' }}>
        <h3>ℹ️ Financial Workflow</h3>
        <ul>
          <li><strong>Revenue:</strong> Only counts confirmed & completed bookings (25% commission retained)</li>
          <li><strong>Refunds:</strong> 10% deduction (5% admin, 5% driver fee) when passengers cancel</li>
          <li><strong>Payouts:</strong> Settle to release funds to bus owners/drivers</li>
        </ul>
      </article>
    </section>
  );
};

export default Financials;
