import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsScreen extends StatelessWidget {
  final String busId;
  const BookingsScreen({super.key, required this.busId});

  // තනි Booking එකක් Confirm කරන Function එක (පරණ එකමයි)
  Future<void> _confirm(BuildContext context, String id, double price) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'confirmed'});
      await FirebaseFirestore.instance.collection('buses').doc(busId).update({'totalRevenue': FieldValue.increment(price)});
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Confirmed!")));
    } catch (e) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 🔥 NEW: මුළු ලිස්ට් එකම සුද්ද කරන Function එක
  Future<void> _clearJourney(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Finish & Clear Journey?"),
        content: const Text("This will mark ALL current bookings as 'Completed' and clear all booked seats. Use this only after the trip ends."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Batch Write (ඔක්කොම එකපාර වෙනස් කරන්න)
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // 1. මේ බස් එකේ Active Bookings ටික ගන්න (Completed නැති ඒවා)
        var bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('busId', isEqualTo: busId)
            .where('status', whereIn: ['pending', 'upcoming', 'confirmed']) // මේ Status තියෙන ඒවා විතරයි
            .get();

        // ඒවා 'completed' කරන්න ලිස්ට් එකට දානවා
        for (var doc in bookingsSnapshot.docs) {
          batch.update(doc.reference, {'status': 'completed'});
        }

        // 2. බස් එකේ Seats ටික හිස් කරන්න ලිස්ට් එකට දානවා
        var busRef = FirebaseFirestore.instance.collection('buses').doc(busId);
        batch.update(busRef, {'bookedSeats': []});

        // 3. ඔක්කොම එකපාර ක්‍රියාත්මක කරන්න
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Journey Cleared Successfully!")));
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error clearing: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Manage Bookings", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        // 🔥 අලුත් Clear Button එක
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: "Clear Journey",
            onPressed: () => _clearJourney(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 Filter: Completed නැති ඒවා විතරක් පෙන්නන්න (Pending/Upcoming/Confirmed)
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('busId', isEqualTo: busId)
            .where('status', whereIn: ['pending', 'upcoming', 'confirmed']) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error loading bookings", style: TextStyle(color: Colors.red[400])));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                  const SizedBox(height: 15),
                  Text("All Cleared!", style: TextStyle(color: Colors.grey[500], fontSize: 18)),
                  Text("Ready for next trip.", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool confirmed = data['status'] == 'confirmed';
              List seats = data['seats'] is List ? data['seats'] : [];
              // Price එක සමහර විට String හෝ Double වෙන්න පුළුවන් නිසා ආරක්ෂිතව ගන්නවා
              double price = (data['totalPrice'] is String) 
                  ? double.tryParse(data['totalPrice']) ?? 0.0 
                  : (data['totalPrice'] as num).toDouble();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      // Seat Icon Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: confirmed ? Colors.green[50] : Colors.orange[50], // Pending නම් Orange
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.event_seat, color: confirmed ? Colors.green : Colors.orange, size: 28),
                      ),
                      const SizedBox(width: 15),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Seats: ${seats.join(', ')}",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Price: Rs. $price",
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            // Status Text එකත් පෙන්නමු
                            Text(
                              confirmed ? "Paid & Confirmed" : "Payment Pending",
                              style: TextStyle(
                                color: confirmed ? Colors.green : Colors.redAccent, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Button
                      confirmed 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            children: [
                              Icon(Icons.check, size: 16, color: Colors.green),
                              SizedBox(width: 5),
                              Text("Paid", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => _confirm(context, doc.id, price),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                        ),
                    ],
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