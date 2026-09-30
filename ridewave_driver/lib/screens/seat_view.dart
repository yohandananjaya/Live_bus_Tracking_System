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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Seat Layout", style: TextStyle(fontWeight: FontWeight.bold)),
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

          // 2. Overlapping White Container
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Horizontal Date Picker
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _next7Days.length,
                      itemBuilder: (context, index) {
                        DateTime date = _next7Days[index];
                        bool isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 65,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[800] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Colors.blue[800]! : Colors.grey[300]!, width: 1.5),
                              boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('MMM').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(DateFormat('dd').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 15),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(Colors.white, "Free Seat", true),
                      const SizedBox(width: 20),
                      _legend(Colors.red[400]!, "Booked", false),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Seat Grid
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('busId', isEqualTo: widget.busId)
                          .where('travelDate', isEqualTo: dateStr) // 🔥 Filter by selected date
                          .where('status', whereIn: ['confirmed', 'upcoming', 'pending'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        List<String> bookedSeats = [];
                        for (var doc in snapshot.data!.docs) {
                          List s = doc['seats'] ?? [];
                          for (var seat in s) {
                            bookedSeats.add(seat.toString());
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
                                  child: Icon(Icons.sports_motorsports_outlined, size: 38, color: Colors.grey[400]),
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
                                    bool isBooked = bookedSeats.contains(seatName);

                                    return Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isBooked ? Colors.red[400] : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isBooked ? Colors.red : Colors.grey[300]!, 
                                          width: 1.5
                                        ),
                                        boxShadow: isBooked ? [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3), 
                                            blurRadius: 6, 
                                            offset: const Offset(0, 3)
                                          )
                                        ] : [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2), 
                                            blurRadius: 4, 
                                            offset: const Offset(0, 2)
                                          )
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        seatName, 
                                        style: TextStyle(
                                          color: isBooked ? Colors.white : Colors.black87, 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15
                                        )
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
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
            border: border ? Border.all(color: Colors.grey[400]!, width: 1.5) : null, 
            borderRadius: BorderRadius.circular(6)
          )
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)),
      ],
    );
  }
}