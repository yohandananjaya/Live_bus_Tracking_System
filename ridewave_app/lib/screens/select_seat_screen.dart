import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Booking එක Submit කරන Function එක
  Future<void> _bookSeats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Booking එක Database එකට දානවා (bookingDate එකත් එක්ක)
      await FirebaseFirestore.instance.collection('bookings').add({
        'busId': widget.busId,
        'busName': widget.busName,
        'userId': user.uid,
        'seats': _selectedSeats,
        'totalPrice': _selectedSeats.length * widget.price,
        'bookingDate': FieldValue.serverTimestamp(),
        'travelDate': widget.selectedDate, // 🔥 වැදගත්: ගමන් කරන දවස
        'status': 'upcoming', 
      });

      // සාමාන්‍යයෙන් බස් එකේ Document එකේ bookedSeats අප්ඩේට් කරන්න එපා.
      // මොකද එක එක දවසට සීට් වෙනස් නේ. ඒ නිසා Booking Collection එකෙන් විතරක් බලමු.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Successful!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Seats (${widget.selectedDate})"), backgroundColor: Colors.blue[800]),
      body: Column(
        children: [
          // 1. Seat Grid (Stream Builder එකෙන් එදා දවසට අදාළ බුකින් විතරක් ගන්නවා)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('busId', isEqualTo: widget.busId)
                  .where('travelDate', isEqualTo: widget.selectedDate) // 🔥 මේ දවසට විතරක් ෆිල්ටර් කරනවා
                  .where('status', whereIn: ['confirmed', 'upcoming', 'pending']) // Cancelled/Completed ඇරෙන්න
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // දැනටමත් බුක් වෙලා තියෙන සීට් ටික ලිස්ට් එකකට ගන්නවා
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
                  itemCount: 32, // සීට් ගාණ
                  itemBuilder: (context, index) {
                    // මැද ඉඩ තියන්න (Aisle)
                    if (index % 4 == 2 && index < 28) return const SizedBox();

                    String seatName = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                    
                    bool isTaken = alreadyBooked.contains(seatName);
                    bool isSelected = _selectedSeats.contains(seatName);

                    return GestureDetector(
                      onTap: isTaken ? null : () {
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
                              ? Colors.red[300] // බුක් වෙලා නම් රතු
                              : isSelected 
                                  ? Colors.green // අපි තෝරගත්තා නම් කොළ
                                  : Colors.grey[200], // හිස් නම් අළු
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

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: Rs. ${_selectedSeats.length * widget.price}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _selectedSeats.isEmpty ? null : _bookSeats,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                  child: const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}