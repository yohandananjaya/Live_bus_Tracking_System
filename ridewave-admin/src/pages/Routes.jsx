import { useEffect, useMemo, useState } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';

const RoutesPage = () => {
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [draft, setDraft] = useState({
    busId: '',
    dayOfWeek: 'Monday',
    routeFrom: '',
    routeTo: '',
    departureTime: '',
    price: '',
  });

  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Fetch schedules from Firestore in real-time
  useEffect(() => {
    setLoading(true);
    setError('');

    try {
      const unsubscribe = onSnapshot(
        collection(db, 'schedules'),
        (snapshot) => {
          const schedulesData = snapshot.docs.map((doc) => ({
            id: doc.id,
            busId: doc.data().busId || '',
            dayOfWeek: doc.data().dayOfWeek || 'Monday',
            routeFrom: doc.data().routeFrom || '',
            routeTo: doc.data().routeTo || '',
            departureTime: doc.data().departureTime || '',
            price: doc.data().price || 0,
          }));
          setSchedules(schedulesData);
          setLoading(false);
        },
        (err) => {
          console.error('Error fetching schedules:', err);
          setError('Failed to load schedules. Please try again.');
          setLoading(false);
        }
      );

      return () => unsubscribe();
    } catch (err) {
      console.error('Error setting up schedules listener:', err);
      setError('Error connecting to database.');
      setLoading(false);
    }
  }, []);

  const title = useMemo(
    () => 'Add New Weekly Schedule',
    []
  );

  const resetDraft = () => {
    setDraft({
      busId: '',
      dayOfWeek: 'Monday',
      routeFrom: '',
      routeTo: '',
      departureTime: '',
      price: '',
    });
    setError('');
  };

  const handleChange = (key, value) => {
    setDraft((current) => ({ ...current, [key]: value }));
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    setNotice('');
    setError('');

    if (!draft.busId || !draft.routeFrom || !draft.routeTo || !draft.departureTime || !draft.price) {
      setError('Please fill all schedule fields.');
      return;
    }

    if (isNaN(parseFloat(draft.price)) || parseFloat(draft.price) <= 0) {
      setError('Price must be a positive number.');
      return;
    }

    setNotice('Schedule feature is read-only. Drivers manage schedules via their mobile app.');
    resetDraft();
  };

  return (
    <section className="panel">
      <div className="routes-header">
        <div>
          <h2>Weekly Schedules</h2>
          <p className="panel-copy">View bus schedules managed by drivers via the mobile app.</p>
        </div>
        <span className="chip chip-blue">{schedules.length} Schedules</span>
      </div>

      {error && <p className="form-notice error">{error}</p>}
      {notice && <p className="form-notice success">{notice}</p>}

      {loading ? (
        <p className="loading-text">Loading schedules...</p>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Bus ID</th>
                <th>Day of Week</th>
                <th>From</th>
                <th>To</th>
                <th>Departure Time</th>
                <th>Price (LKR)</th>
              </tr>
            </thead>
            <tbody>
              {schedules.length > 0 ? (
                schedules.map((schedule) => (
                  <tr key={schedule.id}>
                    <td>{schedule.busId}</td>
                    <td>{schedule.dayOfWeek}</td>
                    <td>{schedule.routeFrom}</td>
                    <td>{schedule.routeTo}</td>
                    <td>{schedule.departureTime}</td>
                    <td>{schedule.price}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td className="empty-row" colSpan="6">
                    No schedules available. Drivers add schedules via their mobile app.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      <article className="panel info-box">
        <h3>ℹ️ About Schedules</h3>
        <p>Schedules are created and managed by <strong>drivers</strong> through the mobile app. The admin panel displays these schedules for reference only.</p>
        <ul>
          <li>Drivers add weekly recurring schedules for their buses.</li>
          <li>Passengers see available schedules and book seats via the passenger app.</li>
          <li>Prices per route are set by drivers when creating schedules.</li>
        </ul>
      </article>
    </section>
  );
};

export default RoutesPage;
