import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SeatView extends StatefulWidget {
  final String busId;
  const SeatView({super.key, required this.busId});

  @override
  State<SeatView> createState() => _SeatViewState();
}

class _SeatViewState extends State<SeatView> {
  DateTime _selectedDate = DateTime.now(); // සීට් බලන්න ඕන දිනය

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seat Layout"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            label: Text(dateStr, style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 බස් එකේ Document එකෙන් නෙවෙයි, Booking Collection එකෙන් දිනයට අදාළව ගන්නවා
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('busId', isEqualTo: widget.busId)
            .where('travelDate', isEqualTo: dateStr) // දිනය අනුව ෆිල්ටර්
            .where('status', whereIn: ['confirmed', 'upcoming', 'pending'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // බුක් වෙලා තියෙන සීට් ටික ලිස්ට් එකකට ගන්නවා
          List<String> bookedSeats = [];
          for (var doc in snapshot.data!.docs) {
            List s = doc['seats'] ?? [];
            for (var seat in s) {
              bookedSeats.add(seat.toString());
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(Colors.white, "Free", true),
                    const SizedBox(width: 20),
                    _legend(Colors.red, "Booked (${bookedSeats.length})", false),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: 32, // සීට් ගාණ
                  itemBuilder: (context, index) {
                    if (index % 4 == 2 && index < 28) return const SizedBox(); // Aisle
                    
                    String seatName = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                    bool isBooked = bookedSeats.contains(seatName);

                    return Container(
                      decoration: BoxDecoration(
                        color: isBooked ? Colors.red : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      alignment: Alignment.center,
                      child: Text(seatName, style: TextStyle(color: isBooked ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legend(Color color, String text, bool border) {
    return Row(
      children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(color: color, border: border ? Border.all(color: Colors.grey) : null, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 5),
        Text(text)
      ],
    );
  }
}