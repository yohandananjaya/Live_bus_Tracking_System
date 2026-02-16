import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please Login to see bookings"));
    }

    return DefaultTabController(
      length: 2,
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
              Tab(text: "Upcoming"),
              Tab(text: "History"), // නම වෙනස් කළා 'History' කියලා (Completed + Confirmed)
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Upcoming Tab (Pending හෝ Upcoming ඒවා)
            _buildBookingList(context, user.uid, ['upcoming', 'pending']),
            
            // 2. History Tab (Driver Confirm කරපු ඒවා සහ Complete වුන ඒවා)
            _buildBookingList(context, user.uid, ['confirmed', 'completed']),
          ],
        ),
      ),
    );
  }

  // Booking List Widget (Updated to accept a List of statuses)
  Widget _buildBookingList(BuildContext context, String userId, List<String> statusList) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: statusList) // වෙනස්කම: isEqualTo වෙනුවට whereIn දැම්මා
          .orderBy('bookingDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            // Get Data
            String bookingId = doc.id;
            String busId = data['busId'] ?? '';
            String busName = data['busName'] ?? 'Bus';
            String route = data['route'] ?? '';
            List<dynamic> seats = data['seats'] ?? [];
            String seatsString = seats.join(', ');
            String price = "Rs. ${data['totalPrice']}";
            String status = data['status'] ?? 'upcoming'; // Status එක ගන්නවා

            return _buildBookingCard(
              context, bookingId, busId, busName, route, seatsString, seats, price, status
            );
          },
        );
      },
    );
  }

  // --- Cancel Booking Function ---
  Future<void> _cancelBooking(BuildContext context, String bookingId, String busId, List<dynamic> seats) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();

      await FirebaseFirestore.instance.collection('buses').doc(busId).update({
        'bookedSeats': FieldValue.arrayRemove(seats)
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Cancelled Successfully")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cancelling: $e")));
      }
    }
  }

  Widget _buildBookingCard(BuildContext context, String bookingId, String busId, String busName, String route, String seatsString, List<dynamic> seatList, String price, String status) {
    
    // Status එක අනුව පාට තීරණය කිරීම
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
      showCancelButton = true; // Upcoming නම් විතරක් Cancel කරන්න පුළුවන්
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
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
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(
                  statusText, 
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)
                ),
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
                    const Text("Route", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),
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
          
          // Confirmed හෝ Completed ඒවා Cancel කරන්න බැරි වෙන්න හදලා තියෙන්නේ
          if (showCancelButton) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelBooking(context, bookingId, busId, seatList),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Cancel Booking", style: TextStyle(color: Colors.red)),
              ),
            )
          ]
        ],
      ),
    );
  }
}