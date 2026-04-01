import { useEffect, useState } from 'react';
import { doc, getDoc, setDoc, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';

const PricingSettings = () => {
  const [pricing, setPricing] = useState({
    baseFare: 27.0,
    perKmRate: 5.0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [notice, setNotice] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  // Fetch pricing settings in real-time
  useEffect(() => {
    setLoading(true);
    setError(null);

    try {
      const settingsRef = doc(db, 'settings', 'pricing');

      // Listen for real-time updates
      const unsubscribe = onSnapshot(
        settingsRef,
        (docSnapshot) => {
          if (docSnapshot.exists()) {
            const data = docSnapshot.data();
            setPricing({
              baseFare: parseFloat(data.baseFare) || 27.0,
              perKmRate: parseFloat(data.perKmRate) || 5.0,
            });
          } else {
            // Document doesn't exist, use defaults
            setPricing({
              baseFare: 27.0,
              perKmRate: 5.0,
            });
          }
          setLoading(false);
        },
        (err) => {
          console.error('Error fetching pricing settings:', err);
          setError('Failed to load pricing settings.');
          setLoading(false);
        }
      );

      return () => unsubscribe();
    } catch (err) {
      console.error('Error setting up pricing listener:', err);
      setError('Error connecting to database.');
      setLoading(false);
    }
  }, []);

  // Handle input changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setPricing((prev) => ({
      ...prev,
      [name]: parseFloat(value) || 0,
    }));
  };

  // Save pricing settings to Firestore
  const handleSave = async (e) => {
    e.preventDefault();
    setIsSaving(true);
    setError(null);
    setNotice('');

    try {
      // Validate inputs
      if (pricing.baseFare <= 0 || pricing.perKmRate <= 0) {
        setError('Base fare and per-km rate must be greater than 0.');
        setIsSaving(false);
        return;
      }

      const settingsRef = doc(db, 'settings', 'pricing');

      await setDoc(settingsRef, {
        baseFare: pricing.baseFare,
        perKmRate: pricing.perKmRate,
        updatedAt: new Date().toISOString(),
      });

      setNotice('Pricing settings updated successfully!');
      setTimeout(() => setNotice(''), 3000);
    } catch (err) {
      console.error('Error saving pricing settings:', err);
      setError('Failed to save pricing settings. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) {
    return (
      <section className="panel">
        <div className="panel-head">
          <h2>Pricing Settings</h2>
        </div>
        <p className="loading-text">Loading pricing configuration...</p>
      </section>
    );
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>Pricing Settings</h2>
          <p className="panel-copy">Configure global ticket pricing parameters. These values are used by the Driver App to calculate fares.</p>
        </div>
      </div>

      {error && <p className="form-notice error">{error}</p>}
      {notice && <p className="form-notice success">{notice}</p>}

      <article className="panel">
        <form onSubmit={handleSave}>
          <div className="form-group">
            <label htmlFor="baseFare">
              Base Fare (LKR)
              <span className="form-hint">Starting price for any trip</span>
            </label>
            <input
              type="number"
              id="baseFare"
              name="baseFare"
              min="0"
              step="0.01"
              value={pricing.baseFare}
              onChange={handleInputChange}
              placeholder="Enter base fare"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="perKmRate">
              Per KM Rate (LKR)
              <span className="form-hint">Price per kilometer traveled</span>
            </label>
            <input
              type="number"
              id="perKmRate"
              name="perKmRate"
              min="0"
              step="0.01"
              value={pricing.perKmRate}
              onChange={handleInputChange}
              placeholder="Enter per-km rate"
              required
            />
          </div>

          <div className="pricing-preview">
            <h4>Price Calculation Formula:</h4>
            <p className="formula">
              <strong>Total Price = Base Fare + (Distance in KM × Per KM Rate)</strong>
            </p>
            <p className="example">
              Example: {pricing.baseFare} + (50 × {pricing.perKmRate}) = <strong>LKR {(pricing.baseFare + 50 * pricing.perKmRate).toLocaleString()}</strong> for a 50 km trip
            </p>
          </div>

          <div className="form-actions">
            <button
              type="submit"
              className="primary-btn"
              disabled={isSaving}
            >
              {isSaving ? 'Saving...' : 'Save Settings'}
            </button>
          </div>
        </form>
      </article>

      <article className="panel info-box">
        <h3>ℹ️ How This Works</h3>
        <ul>
          <li><strong>Driver App:</strong> Reads these settings to calculate passenger fares in real-time.</li>
          <li><strong>Passenger App:</strong> Displays the calculated fare before booking.</li>
          <li><strong>Web Admin:</strong> You can update these values anytime, and changes apply immediately.</li>
          <li><strong>Bookings:</strong> Each booking stores the final price in the <code>totalPrice</code> field.</li>
        </ul>
      </article>
    </section>
  );
};

export default PricingSettings;
