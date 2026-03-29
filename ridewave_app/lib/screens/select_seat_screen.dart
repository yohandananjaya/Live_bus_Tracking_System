import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart'; // 🔥 PayHere Package එක

class SelectSeatScreen extends StatefulWidget {
  final String busId;
  final String busName;
  final double price;
  final String selectedDate; // "2026-02-18" වගේ String එකක්

  const SelectSeatScreen({
    super.key,
    required this.busId,
    required this.busName,
    required this.price,
    required this.selectedDate,
  });

  @override
  State<SelectSeatScreen> createState() => _SelectSeatScreenState();
}

class _SelectSeatScreenState extends State<SelectSeatScreen> {
  final List<String> _selectedSeats = [];
  bool _isProcessing = false; // Payment එක වෙනකම් Loading පෙන්නන්න

  // --- 1. Booking එක 'pending' විදියට Save කරලා Payment එකට යවනවා ---
  Future<void> _proceedToPayment() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one seat.")));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      double totalPrice = _selectedSeats.length * widget.price;

      // A. Database එකේ 'pending' (Lock) විදියට Save කරනවා
      DocumentReference docRef = await FirebaseFirestore.instance.collection('bookings').add({
        'busId': widget.busId,
        'busName': widget.busName,
        'userId': user.uid,
        'seats': _selectedSeats,
        'totalPrice': totalPrice,
        'bookingDate': FieldValue.serverTimestamp(),
        'travelDate': widget.selectedDate, 
        'status': 'pending', // 🔥 වෙන කාටවත් ගන්න බැරි වෙන්න Lock කළා
      });

      String newBookingId = docRef.id;

      // B. PayHere එක Open කරනවා
      _startPayHerePayment(newBookingId, totalPrice, user);

    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 2. PayHere Payment Logic එක ---
  void _startPayHerePayment(String bookingId, double amount, User user) {
    Map paymentObject = {
      "sandbox": true, // 🔥 Testing Mode
      "merchant_id": "1234784", // ඔයාගේ Merchant ID එක
      "merchant_secret": "MTY5NDMyODQxODM5NTQyOTk4NzcyMzM5NjYxNjE1OTM5NjY2MDM3", // ඔයාගේ Secret එක
      "notify_url": "https://sandbox.payhere.lk",
      "order_id": bookingId,
      "items": "RideWave Ticket - ${widget.busName}",
      "amount": amount.toString(),
      "currency": "LKR",
      "first_name": user.displayName ?? "Passenger",
      "last_name": "",
      "email": user.email ?? "passenger@ridewave.lk",
      "phone": "0700000000",
      "address": "Sri Lanka",
      "city": "Colombo",
      "country": "Sri Lanka",
    };

    PayHere.startPayment(
      paymentObject,
      (paymentId) async {
        // ✅ ගෙවීම සාර්ථකයි (SUCCESS)
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'status': 'confirmed', // Lock කරපු එක Confirm කළා
          'paymentId': paymentId,
        });
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Successful! Seats Booked.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          Navigator.popUntil(context, (route) => route.isFirst); // Home එකට යවනවා
        }
      },
      (error) async {
        // ❌ ගෙවීම අසාර්ථකයි (ERROR)
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete(); // Lock කරපු එක මකනවා
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $error"), backgroundColor: Colors.red));
        }
      },
      () async {
        // ⚠️ මගියා Popup එක Close කළා (DISMISSED)
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete(); // Lock කරපු එක මකනවා
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Cancelled. Seats Released.")));
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Seats (${widget.selectedDate})"), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
      body: Column(
        children: [
          // 1. Seat Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('busId', isEqualTo: widget.busId)
                  .where('travelDate', isEqualTo: widget.selectedDate)
                  .where('status', whereIn: ['confirmed', 'upcoming', 'pending']) // Pending ඒවත් පෙන්නනවා (අනිත් අයට ගන්න බෑ)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<String> alreadyBooked = [];
                for (var doc in snapshot.data!.docs) {
                  List seats = doc['seats'] ?? [];
                  for (var seat in seats) {
                    alreadyBooked.add(seat.toString());
                  }
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: 32, 
                  itemBuilder: (context, index) {
                    if (index % 4 == 2 && index < 28) return const SizedBox();

                    String seatName = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                    
                    bool isTaken = alreadyBooked.contains(seatName);
                    bool isSelected = _selectedSeats.contains(seatName);

                    return GestureDetector(
                      onTap: (isTaken || _isProcessing) ? null : () {
                        setState(() {
                          if (isSelected) {
                            _selectedSeats.remove(seatName);
                          } else {
                            _selectedSeats.add(seatName);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isTaken 
                              ? Colors.red[300] 
                              : isSelected 
                                  ? Colors.green 
                                  : Colors.grey[200], 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.green : Colors.grey),
                        ),
                        child: Center(
                          child: isTaken 
                            ? const Icon(Icons.close, color: Colors.white) 
                            : Text(seatName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. Bottom Bar (Payment Button)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Total Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("Rs. ${_selectedSeats.length * widget.price}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                ElevatedButton(
                  onPressed: (_selectedSeats.isEmpty || _isProcessing) ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}