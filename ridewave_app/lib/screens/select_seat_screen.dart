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

  Widget _buildLegendItem(Color color, String text, bool hasBorder) {
    return Row(
      children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey[400]!) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Select Seats", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Background Header Image
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/home_bg.jpg'), fit: BoxFit.cover),
              ),
              child: Container(color: Colors.black.withOpacity(0.6)), // Dark overlay
            ),
          ),

          // 2. Header Texts
          Positioned(
            top: 100, left: 30, right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.busName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 5),
                    Text(widget.selectedDate, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          // 3. Overlapping White Container
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.white, "Available", true),
                      const SizedBox(width: 15),
                      _buildLegendItem(Colors.green, "Selected", false),
                      const SizedBox(width: 15),
                      _buildLegendItem(Colors.red[400]!, "Booked", false),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Seat Grid
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('busId', isEqualTo: widget.busId)
                          .where('travelDate', isEqualTo: widget.selectedDate)
                          .where('status', whereIn: ['confirmed', 'upcoming', 'pending'])
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

                        final List<List<int?>> seatLayout = [
                          [1, 2, null, 3, 4, 5],
                          [6, 7, null, 8, 9, 10],
                          [11, 12, null, 13, 14, 15],
                          [16, 17, null, 18, 19, 20],
                          [21, 22, null, 23, 24, 25],
                          [26, 27, null, 28, 29, 30],
                          [31, 32, null, 33, 34, 35],
                          [36, 37, null, 38, 39, 40],
                          [41, 42, null, 43, 44, 45],
                          [null, null, null, 46, 47, 48],
                          [49, 50, 51, 52, 53, 54],
                        ];

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                          children: [
                            // Steering Wheel
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 15, bottom: 20, top: 10),
                                  child: Icon(Icons.sports_motorsports_outlined, size: 38, color: Colors.grey[400]), // Looks like a wheel
                                )
                              ],
                            ),
                            // Seat Rows
                            ...seatLayout.map((row) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: row.map((seatNum) {
                                    if (seatNum == null) {
                                      return const SizedBox(width: 40); // Aisle
                                    }

                                    String seatName = seatNum.toString().padLeft(2, '0');
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
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: isTaken 
                                              ? Colors.red[400] 
                                              : isSelected 
                                                  ? Colors.green 
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isTaken ? Colors.red : isSelected ? Colors.green : Colors.grey[300]!, 
                                            width: 1.5
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isSelected ? Colors.green : Colors.grey).withOpacity(0.3), 
                                              blurRadius: 6, 
                                              offset: const Offset(0, 3)
                                            )
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            seatName, 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 15, 
                                              color: isTaken || isSelected ? Colors.white : Colors.black87
                                            )
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }),
                            const SizedBox(height: 20), // Bottom padding
                          ],
                        );
                      },
                    ),
                  ),

                  // 4. Bottom Payment Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Total Price", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text("Rs. ${_selectedSeats.length * widget.price}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: (_selectedSeats.isEmpty || _isProcessing) ? null : _proceedToPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800], 
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), 
                            elevation: 5,
                            shadowColor: Colors.blue.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                          child: _isProcessing 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}