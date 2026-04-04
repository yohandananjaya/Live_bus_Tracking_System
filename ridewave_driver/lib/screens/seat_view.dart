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
  // 🔥 දවස් 7ක ලිස්ට් එකක් හදාගන්නවා
  final List<DateTime> _next7Days = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _next7Days[0]; // Default අද දවස
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Seat Layout"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 1. දවස් 7 තෝරන Horizontal List එක ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _next7Days.length,
                itemBuilder: (context, index) {
                  DateTime date = _next7Days[index];
                  bool isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isSelected ? Colors.blue[800]! : Colors.grey[300]!),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('MMM').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 11)),
                          Text(DateFormat('dd').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- 2. Legend (Free / Booked) ---
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend(Colors.white, "Free Seat", true),
                const SizedBox(width: 20),
                _legend(Colors.red, "Booked", false),
              ],
            ),
          ),

          // --- 3. Seat Grid ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('busId', isEqualTo: widget.busId)
                  .where('travelDate', isEqualTo: dateStr) // 🔥 තෝරපු දවසින් ෆිල්ටර් වෙනවා
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

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10
                  ),
                  itemCount: 32, // සීට් ගාණ
                  itemBuilder: (context, index) {
                    if (index % 4 == 2 && index < 28) return const SizedBox(); // Aisle (මැද හිඩැස)
                    
                    String seatName = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                    bool isBooked = bookedSeats.contains(seatName);

                    return Container(
                      decoration: BoxDecoration(
                        color: isBooked ? Colors.red[400] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isBooked ? Colors.red : Colors.grey[400]!, width: 1.5),
                        boxShadow: isBooked ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        seatName, 
                        style: TextStyle(
                          color: isBooked ? Colors.white : Colors.black87, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        )
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text, bool border) {
    return Row(
      children: [
        Container(
          width: 20, 
          height: 20, 
          decoration: BoxDecoration(
            color: color, 
            border: border ? Border.all(color: Colors.grey) : null, 
            borderRadius: BorderRadius.circular(5)
          )
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}