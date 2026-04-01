# RideWave Web Admin Panel - Firebase Integration Update

## Summary of Changes

This document outlines all the Firebase Firestore integrations completed for the RideWave Web Admin Panel to connect with real-time data from the Passenger App and Driver App.

---

## ✅ Components Updated

### 1. **Financials.jsx** ✨ ENHANCED
**Location:** `src/pages/Financials.jsx`

**Features:**
- ✅ Real-time bookings fetched from `bookings` collection (status: confirmed/completed)
- ✅ Revenue calculation with 25% commission deduction
- ✅ **NEW Refund Management Tab:**
  - Fetch refund requests (status: refund_requested)
  - Auto-calculate 10% deduction split (5% admin + 5% driver)
  - Approve refunds with batch operations:
    - Update booking status to `refunded`
    - Remove seats from bus `bookedSeats` array using `arrayRemove()`
    - Add driver fee to `payouts` collection
- ✅ **Driver Payouts Tab:**
  - Manual payout settlement
  - Create settlement records in `payouts` collection

**Firestore Collections Used:**
- `bookings` (read with filters)
- `buses` (update bookedSeats)
- `payouts` (create settlement records)

---

### 2. **Routes.jsx** ✨ NEW
**Location:** `src/pages/Routes.jsx`

**Features:**
- ✅ Real-time schedules fetched from `schedules` collection
- ✅ Displays weekly routes managed by drivers via mobile app
- ✅ Read-only view (drivers manage schedules in their app)
- ✅ Shows: busId, dayOfWeek, routeFrom, routeTo, departureTime, price

**Firestore Collections Used:**
- `schedules` (read-only)

**Example Data:**
```json
{
  "busId": "ND-4532",
  "dayOfWeek": "Monday",
  "routeFrom": "Colombo",
  "routeTo": "Kandy",
  "departureTime": "08:00 AM",
  "price": 420
}
```

---

### 3. **Alerts.jsx** ✨ UPDATED
**Location:** `src/pages/Alerts.jsx`

**Features:**
- ✅ Real-time alerts/reports from `reports` collection
- ✅ Filters by type: SOS vs Report
- ✅ Filters by status: Open alerts only
- ✅ Reply system with timestamp tracking
- ✅ Authority escalation logging
- ✅ Mark as resolved (updates status to 'Resolved')

**Firestore Collections Used:**
- `reports` (read & update)

**Example Data:**
```json
{
  "busId": "ND-4532",
  "type": "SOS",
  "message": "Passenger collapse reported",
  "severity": "Critical",
  "senderType": "Passenger",
  "senderName": "J. Silva",
  "timestamp": Timestamp,
  "status": "Open"
}
```

---

### 4. **Pricing Settings** ✨ NEW COMPONENT
**Location:** `src/pages/PricingSettings.jsx`

**Features:**
- ✅ Edit global pricing parameters from `settings/pricing` document
- ✅ Real-time sync with `onSnapshot`
- ✅ Fields: baseFare (default: 27.0 LKR), perKmRate (default: 5.0 LKR/km)
- ✅ Price calculation formula preview
- ✅ Drivers read these values to calculate fares dynamically

**Firestore Path:**
```
settings/pricing
{
  "baseFare": 27.0,
  "perKmRate": 5.0,
  "updatedAt": "2026-04-01T10:30:00Z"
}
```

---

## 📊 Firestore Schema Reference

### 1. **buses** Collection
```json
{
  "busNo": "ND-4532",
  "busType": "AC Coach",
  "totalSeats": 45,
  "ownerName": "R. Mendis",
  "ownerNIC": "123456789V",
  "driverContact": "+94701234567",
  "accessCode": "ACCESS-123",
  "status": "Live",  // 'Live', 'Idle', 'Offline'
  "latitude": 6.9271,
  "longitude": 80.7789,
  "bookedSeats": [1, 2, 3, 15, 16]
}
```

### 2. **bookings** Collection
```json
{
  "busId": "ND-4532",
  "busNo": "ND-4532",
  "bookingRef": "RW-8492",
  "userId": "user123",
  "seats": [1, 2, 3],
  "totalPrice": 1260,
  "travelDate": "2026-04-05",
  "status": "confirmed",  // 'pending', 'confirmed', 'completed', 'refund_requested', 'refunded'
  "refundAmount": 0,
  "adminFee": 0,
  "driverFee": 0,
  "timestamp": Timestamp
}
```

### 3. **schedules** Collection
```json
{
  "busId": "ND-4532",
  "dayOfWeek": "Monday",
  "routeFrom": "Colombo",
  "routeTo": "Kandy",
  "departureTime": "08:00 AM",
  "price": 420
}
```

### 4. **reports** Collection
```json
{
  "busId": "ND-4532",
  "type": "SOS",  // 'SOS', 'Report'
  "message": "Passenger collapse reported near seat 14",
  "severity": "Critical",  // 'Critical', 'High', 'Medium', 'Low'
  "senderType": "Passenger",  // 'Passenger', 'Driver'
  "senderName": "J. Silva",
  "timestamp": Timestamp,
  "status": "Open"  // 'Open', 'Resolved'
}
```

### 5. **payouts** Collection
```json
{
  "busId": "ND-4532",
  "busNo": "ND-4532",
  "amountTransferred": 9640,
  "date": "2026-04-01T12:00:00Z",
  "status": "settled",  // 'pending', 'settled'
  "type": "commission",  // 'commission', 'refund_fee'
  "refundId": "docId"  // only for refund_fee type
}
```

### 6. **settings/pricing** Document
```json
{
  "baseFare": 27.0,
  "perKmRate": 5.0,
  "updatedAt": "2026-04-01T10:30:00Z"
}
```

---

## 🔄 Financial Workflow

### Revenue Flow
1. Passenger books seats → Creates booking with `status: pending`
2. Payment processed → Status changes to `confirmed`
3. Trip completed → Status changes to `completed`
4. Admin panel counts ONLY `confirmed` or `completed` bookings
5. 25% commission retained by RideWave, 75% goes to driver

### Refund Flow
1. Passenger cancels → Status becomes `refund_requested`
2. Admin sees refund in Refunds tab
3. Admin clicks "Approve Refund":
   - 10% deduction calculated (5% admin + 5% driver)
   - Status updated to `refunded`
   - Seats removed from `buses.bookedSeats` array
   - Driver fee added to `payouts` collection as `refund_fee`
4. Passenger receives `totalPrice - 10%`

### Payout Flow
1. Driver accumulates confirmed bookings
2. Admin can see total due amount
3. Admin clicks "Settle" to:
   - Create settlement record in `payouts` collection
   - Status changes to `Settled`
   - Amount released to driver

---

## 🚀 Installation & Usage

### Step 1: Move Pricing Settings Component
Copy `Financials_updated.jsx` to `Financials.jsx`:
```bash
# This file should replace the old Financials.jsx
cp src/pages/Financials_updated.jsx src/pages/Financials.jsx
```

### Step 2: Add PricingSettings to Routes
Update your routing file to include:
```jsx
import PricingSettings from './pages/PricingSettings';

// Add to route config:
<Route path="/settings/pricing" element={<PricingSettings />} />
```

### Step 3: Update Navigation
Add links in your sidebar/nav:
```jsx
<a href="/settings/pricing" className="nav-link">⚙️ Pricing Settings</a>
<a href="/financials" className="nav-link">💰 Financials</a>
<a href="/routes" className="nav-link">🗺️ Routes</a>
<a href="/alerts" className="nav-link">🚨 Alerts</a>
```

---

## ✨ Key Features

| Feature | Component | Status |
|---------|-----------|--------|
| Real-time Bookings | Financials | ✅ Complete |
| Revenue Calculation | Financials | ✅ Complete |
| Refund Requests | Financials | ✅ Complete |
| 10% Refund Deduction | Financials | ✅ Complete |
| Seat Removal (arrayRemove) | Financials | ✅ Complete |
| Driver Payouts | Financials | ✅ Complete |
| Weekly Schedules | Routes | ✅ Complete |
| SOS/Reports | Alerts | ✅ Complete |
| Authority Escalation | Alerts | ✅ Complete |
| Global Pricing | PricingSettings | ✅ Complete |
| onSnapshot Listeners | All | ✅ Complete |
| Error Handling | All | ✅ Complete |
| Loading States | All | ✅ Complete |

---

## 🔗 Integration Notes

### Booking Display
- Uses `bookingRef` field for human-readable ID (e.g., "RW-8492")
- Uses `busNo` instead of busId for better readability
- Fallback generation if field missing: `RW-${doc.id.substring(0, 6)}`

### Date Formatting
- Handles Firestore Timestamp objects (`.toDate()`)
- Handles string dates
- Handles Date objects
- Shows "N/A" for missing dates

### Commission Calculation
- **Default Rate:** 25% (adjustable in code)
- Formula: `due = totalPrice × (1 - COMMISSION_RATE)`
- Recalculates automatically when new bookings arrive

### Refund Deduction Split
- **Total Deduction:** 10% of booking amount
- **Admin Fee:** 5%
- **Driver Fee:** 5%
- Formula: `refundAmount = totalPrice × 0.90`

---

## ⚠️ Important Notes

1. **Drivers manage schedules** - Routes.jsx is read-only from the admin panel. Drivers add schedules via mobile app.
2. **Pricing is global** - All drivers use the same baseFare and perKmRate from `settings/pricing`.
3. **Commission is deducted automatically** - The 25% commission is calculated in the admin panel, not deducted from driver's view.
4. **Real-time updates** - All components use `onSnapshot()` for live data synchronization.
5. **Refunds release seats** - When refund is approved, seats are immediately available for new bookings.

---

## 📝 Files Modified

```
src/pages/
  ├── Financials.jsx (UPDATED - Added refund management, tabs)
  ├── Routes.jsx (REWRITTEN - Firebase schedules integration)
  ├── Alerts.jsx (UPDATED - Firebase reports integration)
  └── PricingSettings.jsx (NEW)

src/
  └── firebase.js (ALREADY CONFIGURED)
```

---

## ✅ Testing Checklist

- [ ] Financials loads bookings in real-time
- [ ] Revenue total updates automatically
- [ ] Refund requests appear in tab
- [ ] Approve refund creates payout record
- [ ] Settle payout creates settlement record
- [ ] Routes shows schedules from Firestore
- [ ] Alerts filters SOS vs Reports
- [ ] Alerts mark as resolved updates Firestore
- [ ] Pricing Settings loads current values
- [ ] Pricing Settings updates database on save
- [ ] All error messages display properly
- [ ] Loading spinners show during fetch

---

## 🆘 Troubleshooting

### No data showing?
1. Check Firestore collection names match exactly
2. Ensure documents have all required fields
3. Check browser console for error messages
4. Verify Firebase rules allow read/write access

### Dates showing as "Invalid Date"?
1. Ensure dates are stored as Firestore Timestamps or ISO strings
2. Use consistent date format: "YYYY-MM-DD" or Timestamp

### Pricing not updating?
1. Ensure `settings/pricing` document exists at that exact path
2. Check driver app is reading from the same document
3. Verify no Firestore security rules blocking updates

---

**Version:** 1.0.0  
**Last Updated:** April 1, 2026  
**Compatible with:** React 18+, Firebase SDK 9.0+
