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
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Upcoming Bookings Tab
            _buildBookingList(context, user.uid, 'upcoming'),
            
            // 2. Completed Bookings Tab
            _buildBookingList(context, user.uid, 'completed'),
          ],
        ),
      ),
    );
  }

  // Booking List Widget
  Widget _buildBookingList(BuildContext context, String userId, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status) // Filter by status (upcoming/completed)
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
                Text("No $status bookings found.", style: TextStyle(color: Colors.grey[500])),
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
            bool isUpcoming = status == 'upcoming';

            return _buildBookingCard(
              context, bookingId, busId, busName, route, seatsString, seats, price, isUpcoming
            );
          },
        );
      },
    );
  }

  // --- Cancel Booking Function ---
  Future<void> _cancelBooking(BuildContext context, String bookingId, String busId, List<dynamic> seats) async {
    try {
      // 1. Delete the Booking Document
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();

      // 2. Remove booked seats from the Bus Document
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

  Widget _buildBookingCard(BuildContext context, String bookingId, String busId, String busName, String route, String seatsString, List<dynamic> seatList, String price, bool isUpcoming) {
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
                  color: isUpcoming ? Colors.green[50] : Colors.grey[100], 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(
                  isUpcoming ? "Scheduled" : "Completed", 
                  style: TextStyle(color: isUpcoming ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)
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
          if (isUpcoming) ...[
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