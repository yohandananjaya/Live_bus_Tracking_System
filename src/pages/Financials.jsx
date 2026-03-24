import { useMemo, useState } from 'react';

const initialBookings = [
  {
    id: 'BK-1024',
    busNo: 'ND-4532',
    passenger: 'S. Perera',
    route: 'Colombo -> Kandy',
    amount: 420,
    time: '08:15 AM',
    status: 'Paid',
  },
  {
    id: 'BK-1025',
    busNo: 'ND-6711',
    passenger: 'D. Fernando',
    route: 'Negombo -> Colombo',
    amount: 180,
    time: '09:05 AM',
    status: 'Paid',
  },
  {
    id: 'BK-1026',
    busNo: 'ND-4532',
    passenger: 'K. Silva',
    route: 'Colombo -> Kandy',
    amount: 420,
    time: '10:20 AM',
    status: 'Paid',
  },
];

const initialPayouts = [
  {
    id: 'PO-2201',
    driver: 'R. Mendis',
    busNo: 'ND-4532',
    total: 12840,
    commission: 3200,
    due: 9640,
    status: 'Pending',
  },
  {
    id: 'PO-2202',
    driver: 'T. Jayasuriya',
    busNo: 'ND-6711',
    total: 8640,
    commission: 2160,
    due: 6480,
    status: 'Pending',
  },
];

const Financials = () => {
  const [bookings] = useState(initialBookings);
  const [payouts, setPayouts] = useState(initialPayouts);
  const [notice, setNotice] = useState('');

  const totals = useMemo(() => {
    const revenue = bookings.reduce((sum, booking) => sum + booking.amount, 0);
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
  };

  return (
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>Financials & Payouts</h2>
          <p className="panel-copy">Track daily bookings, revenue, and driver payouts.</p>
        </div>
        <span className="chip chip-green">LKR {totals.revenue.toLocaleString()}</span>
      </div>

      {notice && <p className="form-notice success">{notice}</p>}

      <section className="financials-grid">
        <article className="panel">
          <div className="panel-head">
            <h3>All Bookings (Today)</h3>
            <span className="chip">{bookings.length} Bookings</span>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Booking ID</th>
                  <th>Bus</th>
                  <th>Passenger</th>
                  <th>Route</th>
                  <th>Amount (LKR)</th>
                  <th>Time</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map((booking) => (
                  <tr key={booking.id}>
                    <td>{booking.id}</td>
                    <td>{booking.busNo}</td>
                    <td>{booking.passenger}</td>
                    <td>{booking.route}</td>
                    <td>{booking.amount}</td>
                    <td>{booking.time}</td>
                  </tr>
                ))}
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
                  <th>Driver</th>
                  <th>Bus</th>
                  <th>Total Collected</th>
                  <th>Commission</th>
                  <th>Due</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {payouts.map((payout) => (
                  <tr key={payout.id}>
                    <td>{payout.id}</td>
                    <td>{payout.driver}</td>
                    <td>{payout.busNo}</td>
                    <td>{payout.total.toLocaleString()}</td>
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
                ))}
                {payouts.length === 0 && (
                  <tr>
                    <td colSpan="8" className="empty-row">No payouts due right now.</td>
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
