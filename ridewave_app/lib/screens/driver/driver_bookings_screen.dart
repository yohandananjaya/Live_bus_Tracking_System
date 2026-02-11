import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverBookingsScreen extends StatelessWidget {
  final String busId;
  final String ticketPrice; // Revenue හදන්න ඕනේ නිසා Price එක ගන්නවා

  const DriverBookingsScreen({super.key, required this.busId, required this.ticketPrice});

  // Confirm Function
  Future<void> _confirmBooking(BuildContext context, String bookingId, double totalBookingPrice) async {
    try {
      // 1. Booking Status එක 'confirmed' කරනවා
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'confirmed'
      });

      // 2. Bus එකේ Revenue එක වැඩි කරනවා (Atomic Increment)
      await FirebaseFirestore.instance.collection('buses').doc(busId).update({
        'totalRevenue': FieldValue.increment(totalBookingPrice)
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Confirmed! Revenue Updated.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Bookings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('busId', isEqualTo: busId)
            .orderBy('bookingDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No Bookings yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              String status = data['status'] ?? 'upcoming';
              bool isConfirmed = status == 'confirmed';
              double price = (data['totalPrice'] ?? 0).toDouble();

              return Card(
                color: isConfirmed ? Colors.green[50] : Colors.white,
                child: ListTile(
                  title: Text("Seats: ${(data['seats'] as List).join(', ')}"),
                  subtitle: Text("Price: Rs. $price\nStatus: $status"),
                  trailing: isConfirmed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => _confirmBooking(context, doc.id, price),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text("Confirm"),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}