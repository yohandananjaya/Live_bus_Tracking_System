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
      // Query only confirmed and completed bookings
      const q = query(
        collection(db, 'bookings'),
        where('status', 'in', ['confirmed', 'completed'])
      );

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const bookingsData = snapshot.docs.map((doc) => {
            const data = doc.data();
            return {
              id: doc.id,
              bookingRef: data.bookingRef || `RW-${doc.id.substring(0, 6).toUpperCase()}`,
              busId: data.busId || '',
              busNo: data.busNo || '',
              userId: data.userId || '',
              seats: Array.isArray(data.seats) ? data.seats : [],
              totalPrice: parseFloat(data.totalPrice) || 0,
              travelDate: data.travelDate || '',
              status: data.status || 'pending',
              timestamp: data.timestamp || null,
            };
          });

          setBookings(bookingsData);
          setLoading(false);

          // Calculate payouts based on bookings
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
            const adminFee = baseAmount * 0.05; // 5%
            const driverFee = baseAmount * 0.05; // 5%
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

  // Calculate payouts from bookings (commission-based)
  const calculatePayouts = (bookingsData) => {
    const payoutMap = {};
    const COMMISSION_RATE = 0.05; // 5% commission

    bookingsData.forEach((booking) => {
      if (!payoutMap[booking.busId]) {
        payoutMap[booking.busId] = {
          busId: booking.busId,
          busName: booking.busName,
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

  // Calculate total revenue (only from confirmed/completed bookings)
  const totals = useMemo(() => {
    const revenue = bookings.reduce((sum, booking) => sum + booking.totalPrice, 0);
    const totalPayouts = payouts.reduce((sum, payout) => sum + payout.due, 0);
    return { revenue, totalPayouts };
  }, [bookings, payouts]);

  const handleSettle = (payoutId) => {
    setPayouts((current) =>
      current.map((payout) =>
        payout.id === payoutId ? { ...payout, status: 'Settled' } : payout
      )
    );
    setNotice(`${payoutId} marked as settled.`);
    setTimeout(() => setNotice(''), 3000);
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
          <p className="panel-copy">Track daily bookings, revenue, and driver payouts.</p>
        </div>
        <span className="chip chip-green">LKR {totals.revenue.toLocaleString()}</span>
      </div>

      {error && <p className="form-notice error">{error}</p>}
      {notice && <p className="form-notice success">{notice}</p>}

      <section className="financials-grid">
        <article className="panel">
          <div className="panel-head">
            <h3>All Bookings</h3>
            <span className="chip">{bookings.length} Bookings</span>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Booking ID</th>
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
                      <td>{booking.id}</td>
                      <td>{booking.busId}</td>
                      <td>{new Date(booking.travelDate).toLocaleDateString()}</td>
                      <td>{booking.seats.join(', ')}</td>
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
                    <td colSpan="6" className="empty-row">No confirmed or completed bookings yet.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </article>

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
                  <th>Total Collected</th>
                  <th>Commission (5%)</th>
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
                      <td>{payout.totalCollected.toLocaleString()}</td>
                      <td>{payout.commission.toLocaleString()}</td>
                      <td>{payout.due.toLocaleString()}</td>
                      <td>
                        <span className={`chip ${payout.status === 'Settled' ? 'chip-green' : 'chip-amber'}`}>
                          {payout.status}
                        </span>
                      </td>
                      <td>
                        <button
                          type="button"
                          className="ghost-btn"
                          disabled={payout.status === 'Settled'}
                          onClick={() => handleSettle(payout.id)}
                        >
                          Mark Settled
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="7" className="empty-row">No payouts due right now.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </article>
      </section>
    </section>
  );
};

export default Financials;