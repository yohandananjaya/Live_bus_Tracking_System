# 🔧 Firebase Integration API Reference

## Complete Component API Documentation

---

## 📄 Financials.jsx

### Component Import
```jsx
import Financials from './pages/Financials';
```

### Props
None (Component manages its own state)

### State Variables
```jsx
const [bookings, setBookings] = useState([]);      // Current confirmed/completed bookings
const [refundRequests, setRefundRequests] = useState([]);  // Refund requests
const [payouts, setPayouts] = useState([]);        // Calculated driver payouts
const [loading, setLoading] = useState(true);      // Loading state
const [error, setError] = useState('');            // Error messages
const [notice, setNotice] = useState('');          // Success messages
const [activeTab, setActiveTab] = useState('revenue'); // Current tab
```

### Data Structure: Booking
```javascript
{
  id: string,                    // Firestore document ID
  bookingRef: string,            // Human-readable ID (e.g., "RW-8492")
  busId: string,                 // Bus identifier
  busNo: string,                 // Bus number for display
  userId: string,                // Passenger user ID
  seats: number[],               // Array of seat numbers
  totalPrice: number,            // Price in LKR
  travelDate: string|Timestamp,  // Travel date
  status: string,                // 'pending', 'confirmed', 'completed'
  timestamp: Timestamp           // When booking was created
}
```

### Data Structure: Refund Request
```javascript
{
  id: string,                    // Firestore document ID
  bookingRef: string,            // Human-readable booking ID
  busId: string,                 // Bus identifier
  busNo: string,                 // Bus number
  userId: string,                // User ID
  seats: number[],               // Booked seats
  totalPrice: number,            // Original price
  adminFee: number,              // 5% of totalPrice
  driverFee: number,             // 5% of totalPrice
  refundAmount: number,          // 90% of totalPrice (after deductions)
  travelDate: string|Timestamp,
  requestedAt: Timestamp
}
```

### Methods

#### `calculatePayouts(bookingsData)`
**Description:** Calculates driver payouts from bookings  
**Parameters:**
- `bookingsData` (Booking[]): Array of confirmed/completed bookings
**Returns:** void (updates `payouts` state)
**Commission Rate:** 25% (configurable in code)

#### `handleApproveRefund(refundId, busId, seats, driverFee)`
**Description:** Approves refund with atomic operations  
**Parameters:**
- `refundId` (string): Firestore booking document ID
- `busId` (string): Bus document ID
- `seats` (number[]): Seats to remove from bookedSeats
- `driverFee` (number): Driver fee amount
**Firestore Operations:**
1. Update booking: `status = 'refunded'`
2. Remove from bus: `arrayRemove(seats)` from `bookedSeats`
3. Create payout: Add to `payouts` collection
**Returns:** Promise<void>

#### `handleSettle(payoutId)`
**Description:** Settles driver payout  
**Parameters:**
- `payoutId` (string): Payout ID to settle
**Firestore Operations:**
1. Create settlement record in `payouts` collection
2. Update local state to mark as 'Settled'
**Returns:** Promise<void>

### Firestore Queries

#### Revenue Tab Query
```javascript
query(
  collection(db, 'bookings'),
  where('status', 'in', ['confirmed', 'completed'])
)
```
**Real-time:** ✅ Yes (onSnapshot)  
**Filters:** status must be 'confirmed' or 'completed'

#### Refunds Tab Query
```javascript
query(
  collection(db, 'bookings'),
  where('status', '==', 'refund_requested')
)
```
**Real-time:** ✅ Yes (onSnapshot)  
**Filters:** status must be exactly 'refund_requested'

### Calculated Values

#### Revenue Total
```javascript
const revenue = bookings.reduce((sum, booking) => sum + booking.totalPrice, 0);
```

#### Payout Due
```javascript
const totalPayouts = payouts.reduce((sum, payout) => sum + payout.due, 0);
```

#### Pending Refunds
```javascript
const pendingRefunds = refundRequests.reduce((sum, req) => sum + req.refundAmount, 0);
```

### UI Tabs
```
Active Tab          Shows
═══════════════════════════════════════════
'revenue'           Confirmed bookings table
'refunds'           Refund requests with approval buttons
'payouts'           Driver payouts with settle buttons
```

### Error Handling
```javascript
// Connection errors:
catch (err) => setError('Error connecting to database.');

// Firestore listener errors:
(err) => setError('Failed to load bookings. Please try again.');

// Operation errors:
catch (err) => setError('Failed to approve refund. Please try again.');
```

---

## 📄 Routes.jsx

### Component Import
```jsx
import Routes from './pages/Routes';
```

### Props
None (Component manages its own state)

### State Variables
```jsx
const [schedules, setSchedules] = useState([]);    // Weekly schedules
const [loading, setLoading] = useState(true);
const [error, setError] = useState('');
const [notice, setNotice] = useState('');
const [draft, setDraft] = useState({...});         // Form draft (unused)
```

### Data Structure: Schedule
```javascript
{
  id: string,                // Firestore document ID
  busId: string,             // Bus identifier
  dayOfWeek: string,         // 'Monday', 'Tuesday', etc.
  routeFrom: string,         // Starting location
  routeTo: string,           // Destination
  departureTime: string,     // e.g., "08:00 AM"
  price: number              // Price in LKR
}
```

### Firestore Query
```javascript
collection(db, 'schedules')
```
**Real-time:** ✅ Yes (onSnapshot)  
**Filters:** None (shows all schedules)  
**Note:** Read-only view. Drivers manage schedules via mobile app.

### Use Cases
1. Admin views all weekly schedules across all buses
2. See what routes drivers have created
3. Understand pricing per route
4. Monitor schedule changes in real-time

---

## 📄 Alerts.jsx

### Component Import
```jsx
import Alerts from './pages/Alerts';
```

### Props
None (Component manages its own state)

### State Variables
```jsx
const [reports, setReports] = useState([]);        // Current reports
const [activeTab, setActiveTab] = useState('SOS'); // 'SOS' or 'Report'
const [replyDrafts, setReplyDrafts] = useState({}); // Draft replies by reportId
const [replies, setReplies] = useState({});        // Sent replies
const [authorityLogs, setAuthorityLogs] = useState({}); // Authority escalation logs
const [notice, setNotice] = useState('');
const [error, setError] = useState('');
const [loading, setLoading] = useState(true);
```

### Data Structure: Report
```javascript
{
  id: string,                // Firestore document ID
  busId: string,             // Bus identifier
  type: string,              // 'SOS' or 'Report'
  message: string,           // Issue description
  severity: string,          // 'Critical', 'High', 'Medium', 'Low'
  senderType: string,        // 'Passenger' or 'Driver'
  senderName: string,        // Name of person reporting
  timestamp: Timestamp,      // When report was created
  status: string             // 'Open' or 'Resolved'
}
```

### Methods

#### `handleReplyChange(reportId, value)`
**Description:** Updates draft reply text  
**Parameters:**
- `reportId` (string): Report ID
- `value` (string): Reply text
**Returns:** void

#### `handleSendReply(reportId)`
**Description:** Sends reply to reporter  
**Parameters:**
- `reportId` (string): Report ID
**Storage:** Stored in component state (not Firestore)
**Returns:** void

#### `handleConnectAuthority(reportId, authority)`
**Description:** Logs authority escalation  
**Parameters:**
- `reportId` (string): Report ID
- `authority` (string): Authority name (e.g., "Police")
**Storage:** Stored in component state (not Firestore)
**Returns:** void

#### `handleResolve(reportId)`
**Description:** Marks report as resolved  
**Parameters:**
- `reportId` (string): Report ID
**Firestore Operations:**
1. Update: `status = 'Resolved'`
2. Add: `resolvedAt = Timestamp`
**Returns:** Promise<void>

### Firestore Queries

#### SOS Tab Query
```javascript
query(
  collection(db, 'reports'),
  where('type', '==', 'SOS'),
  where('status', '==', 'Open')
)
```

#### Report Tab Query
```javascript
query(
  collection(db, 'reports'),
  where('type', '==', 'Report'),
  where('status', '==', 'Open')
)
```

**Real-time:** ✅ Yes (onSnapshot)  
**Auto-refresh:** When tab changes

### UI Tabs
```
Active Tab    Report Type
════════════════════════════════════
'SOS'         Type = 'SOS'
'Report'      Type = 'Report'
```

### Severity Colors
```javascript
'Critical'  → chip-red
'High'      → chip-amber
'Medium'    → chip-blue
'Low'       → chip-blue
```

### Authorities Available
```javascript
[
  { id: 'transport', label: 'Transport Control' },
  { id: 'police', label: 'Police' },
  { id: 'emergency', label: 'Emergency Service' }
]
```

---

## 📄 PricingSettings.jsx

### Component Import
```jsx
import PricingSettings from './pages/PricingSettings';
```

### Props
None (Component manages its own state)

### State Variables
```jsx
const [pricing, setPricing] = useState({
  baseFare: 27.0,              // Base price in LKR
  perKmRate: 5.0               // Price per kilometer
});
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);
const [notice, setNotice] = useState('');
const [isSaving, setIsSaving] = useState(false);
```

### Data Structure: Pricing
```javascript
{
  baseFare: number,     // Default: 27.0 LKR
  perKmRate: number,    // Default: 5.0 LKR/km
  updatedAt: string     // ISO timestamp
}
```

### Methods

#### `handleInputChange(e)`
**Description:** Updates pricing form input  
**Parameters:**
- `e` (ChangeEvent): React change event
**Returns:** void

#### `handleSave(e)`
**Description:** Saves pricing to Firestore  
**Parameters:**
- `e` (FormEvent): React form submission event
**Validation:**
- baseFare must be > 0
- perKmRate must be > 0
**Firestore Operations:**
1. Save to `settings/pricing` document
2. Set `updatedAt` timestamp
**Returns:** Promise<void>

### Firestore Document Path
```
settings/pricing
```

### Document Fields
```javascript
{
  baseFare: number,      // Required, must be positive
  perKmRate: number,     // Required, must be positive
  updatedAt: Timestamp   // Auto-set on save
}
```

### Formula Preview
```
Total Price = baseFare + (distance × perKmRate)

Example (with defaults):
Total = 27 + (50 × 5) = 27 + 250 = 277 LKR
```

### Firestore Query
```javascript
doc(db, 'settings', 'pricing')
```

**Real-time:** ✅ Yes (onSnapshot)  
**Updates:** ✅ Yes (setDoc)  
**Note:** Drivers read from same document for fare calculation

---

## 🔄 Shared Utilities

### formatDate(dateValue)
**Description:** Safely converts any date format to readable string  
**Parameters:**
- `dateValue` (string|Date|Timestamp|null): Date in any format
**Returns:** string (formatted date or "N/A" if invalid)

**Handles:**
- Firestore Timestamp objects
- ISO string dates ("2026-04-01")
- JavaScript Date objects
- null/undefined values

### formatTime(timestamp)
**Description:** Safely converts timestamp to readable datetime  
**Parameters:**
- `timestamp` (string|Date|Timestamp|null): Timestamp
**Returns:** string (formatted datetime or "N/A")

---

## 📊 Firestore Operations Cheat Sheet

### Read Operations
```javascript
// Single document
const docSnap = await getDoc(doc(db, 'collection', 'docId'));

// Query with real-time listener
onSnapshot(
  query(collection(db, 'collection'), where('field', '==', 'value')),
  (snapshot) => {
    snapshot.docs.forEach(doc => console.log(doc.data()));
  }
);

// Array remove from array field
arrayRemove(value)

// Array union to array field
arrayUnion(value)
```

### Write Operations
```javascript
// Update single document
await updateDoc(doc(db, 'collection', 'docId'), {
  field: newValue
});

// Create new document
await addDoc(collection(db, 'collection'), {
  field: value
});

// Batch write (atomic)
const batch = writeBatch(db);
batch.update(docRef1, {...});
batch.update(docRef2, {...});
await batch.commit();

// Set document (create or overwrite)
await setDoc(doc(db, 'settings', 'pricing'), {
  baseFare: 27.0,
  perKmRate: 5.0
});
```

---

## 🧪 Testing Queries

### Test Booking Creation
```javascript
// In Firebase Console:
bookings > Add document
{
  "busId": "ND-4532",
  "busNo": "ND-4532",
  "bookingRef": "RW-TEST1",
  "userId": "test-user",
  "seats": [1, 2, 3],
  "totalPrice": 1260,
  "travelDate": "2026-04-05",
  "status": "confirmed",
  "timestamp": (server timestamp)
}
```

### Test Refund Request
```javascript
// Change booking status to "refund_requested"
// It will appear in Financials > Refunds tab
```

### Test Alert/Report
```javascript
// In Firebase Console:
reports > Add document
{
  "busId": "ND-4532",
  "type": "SOS",
  "message": "Test emergency",
  "severity": "Critical",
  "senderType": "Passenger",
  "senderName": "Test User",
  "status": "Open",
  "timestamp": (server timestamp)
}
```

### Test Pricing Update
```javascript
// In Firebase Console:
settings > Create document "pricing"
{
  "baseFare": 27.0,
  "perKmRate": 5.0,
  "updatedAt": (server timestamp)
}

// Update via PricingSettings component
// Changes should appear immediately in all clients
```

---

## 🚨 Common Errors & Solutions

### Error: "Cannot read property 'toLocaleDateString' of null"
**Cause:** Date value is null or undefined  
**Solution:** Use `formatDate()` helper function which handles nulls

### Error: "Missing required field 'status' in 'bookings' query"
**Cause:** Document doesn't have the 'status' field  
**Solution:** Ensure all bookings have status field set

### Error: "Cannot update bookings: permission denied"
**Cause:** Firestore security rules don't allow update  
**Solution:** Update security rules to allow admin updates

### Error: "arrayRemove is not a function"
**Cause:** Forgot to import `arrayRemove` from firebase/firestore  
**Solution:** Add to imports: `import { arrayRemove } from 'firebase/firestore'`

### Error: "onSnapshot is not a function"
**Cause:** Firestore reference not properly initialized  
**Solution:** Verify Firebase import: `import { db } from '../firebase'`

---

## 📈 Performance Tips

1. **Use where() clauses** to filter before receiving data
2. **Index common queries** for faster reads
3. **Batch writes** for atomic multi-document updates
4. **Unsubscribe from snapshots** in cleanup to prevent memory leaks
5. **Cache results** locally to reduce Firestore reads

---

## 📚 Related Files

- `src/firebase.js` - Firebase configuration
- `src/pages/Financials.jsx` - Revenue and refund management
- `src/pages/Routes.jsx` - Schedule viewer
- `src/pages/Alerts.jsx` - Report management
- `src/pages/PricingSettings.jsx` - Pricing configuration

---

**Version:** 1.0.0  
**Last Updated:** April 1, 2026
