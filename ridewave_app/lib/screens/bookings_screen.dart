import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'available_buses_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please Login to see bookings"));
    }

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("My Bookings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Search"), 
              Tab(text: "Upcoming"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _AdvanceBookingTab(), 
            _buildBookingList(context, user.uid, ['upcoming', 'pending'], isHistoryTab: false),
            // 🔥 History Tab එකට isHistoryTab: true කියලා යවනවා
            _buildBookingList(context, user.uid, ['confirmed', 'completed'], isHistoryTab: true),
          ],
        ),
      ),
    );
  }

  // --- 🔥 අලුත්: History එක Clear කරන Function එක ---
  Future<void> _clearHistory(BuildContext context, String userId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to clear all your completed past trips? (Upcoming confirmed tickets will not be deleted)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Clear All", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 'completed' වුණු ඒවා විතරක් හොයලා මකනවා
        var snapshots = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed') 
            .get();

        var batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History Cleared Successfully!")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  // Booking List Widget (Clear Button එකත් එක්ක)
  Widget _buildBookingList(BuildContext context, String userId, List<String> statusList, {required bool isHistoryTab}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: statusList) 
          .orderBy('bookingDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.airplane_ticket_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("No bookings found.", style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 🔥 History Tab එකේ නම් විතරක් Clear History බට්න් එක පෙන්නනවා
            if (isHistoryTab)
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _clearHistory(context, userId),
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    label: const Text("Clear History", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: isHistoryTab ? 0 : 20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;

                  String bookingId = doc.id;
                  String busId = data['busId'] ?? '';
                  String busName = data['busName'] ?? 'Bus';
                  String route = data['route'] ?? '';
                  String date = data['travelDate'] ?? 'Unknown Date'; 
                  List<dynamic> seats = data['seats'] ?? [];
                  String seatsString = seats.join(', ');
                  String price = "Rs. ${data['totalPrice']}";
                  String status = data['status'] ?? 'upcoming'; 

                  return _buildBookingCard(context, bookingId, busId, busName, route, date, seatsString, seats, price, status);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId, String busId, List<dynamic> seats) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      await FirebaseFirestore.instance.collection('buses').doc(busId).update({
        'bookedSeats': FieldValue.arrayRemove(seats)
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Cancelled Successfully")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cancelling: $e")));
    }
  }

  Widget _buildBookingCard(BuildContext context, String bookingId, String busId, String busName, String route, String date, String seatsString, List<dynamic> seatList, String price, String status) {
    Color statusColor;
    String statusText;
    bool showCancelButton = false;

    if (status == 'confirmed') {
      statusColor = Colors.green;
      statusText = "Confirmed";
    } else if (status == 'completed') {
      statusColor = Colors.grey;
      statusText = "Completed";
    } else {
      statusColor = Colors.orange;
      statusText = "Scheduled";
      showCancelButton = true; 
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)),
                child: Text(busName, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Route & Date", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(date, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)), 
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Seats", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(seatsString, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Total Price", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(price, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
          if (showCancelButton) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelBooking(context, bookingId, busId, seatList),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Cancel Booking", style: TextStyle(color: Colors.red)),
              ),
            )
          ]
        ],
      ),
    );
  }
}

// Search (Advance Booking) Tab එකේ UI එක
class _AdvanceBookingTab extends StatefulWidget {
  const _AdvanceBookingTab();

  @override
  State<_AdvanceBookingTab> createState() => _AdvanceBookingTabState();
}

class _AdvanceBookingTabState extends State<_AdvanceBookingTab> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  final List<DateTime> _next7Days = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _next7Days[0]; 
  }

  void _searchScheduledBuses() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter From and To locations", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    String dayOfWeek = DateFormat('EEEE').format(_selectedDate); 
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableBusesScreen(
          fromLocation: _fromController.text.trim(),
          toLocation: _toController.text.trim(),
          dayOfWeek: dayOfWeek,
          selectedDate: formattedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Plan your next trip", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 5),
          const Text("Search for scheduled buses and book seats in advance.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(_fromController, "Leaving from (e.g. Galle)", Icons.my_location, Colors.blue),
                const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Divider()),
                _buildInputField(_toController, "Going to (e.g. Hapugala)", Icons.location_on, Colors.red),
                
                const SizedBox(height: 25),
                const Text("Select Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),

                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _next7Days.length,
                    itemBuilder: (context, index) {
                      DateTime date = _next7Days[index];
                      bool isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          width: 65,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? Colors.blue[800]! : Colors.grey[300]!),
                            boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('MMM').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)),
                              Text(DateFormat('dd').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _searchScheduledBuses,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800], 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      shadowColor: Colors.blue.withOpacity(0.5)
                    ),
                    child: const Text("Search Scheduled Buses", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, Color iconColor) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: iconColor),
      ),
    );
  }
}