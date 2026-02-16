import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = timestamp.toDate();
    if (DateTime.now().difference(date).inDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please Login"));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      // 1. මුලින්ම User ගේ Active Bookings ටික හොයාගන්නවා
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: ['confirmed', 'upcoming']) // Active ඒවා විතරයි
            .snapshots(),
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.hasError) return const Center(child: Text("Error loading data"));
          if (bookingSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // User ට Active Bookings මුකුත් නැත්නම් Notification පෙන්නන්නේ නෑ
          if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Active බස් වල ID ටික ලිස්ට් එකකට ගන්නවා
          List<String> activeBusIds = bookingSnapshot.data!.docs
              .map((doc) => doc['busId'] as String)
              .toSet() // එකම බස් එකේ බුකින් 2ක් තිබුනොත් එකක් විතරක් ගන්න
              .toList();

          // 2. දැන් ඒ Bus ID වලට අදාල Notifications විතරක් ගන්නවා
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('busId', whereIn: activeBusIds) // 🔥 Filter by Active Buses Only
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, notifSnapshot) {
              if (notifSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!notifSnapshot.hasData || notifSnapshot.data!.docs.isEmpty) {
                 return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: notifSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = notifSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                  
                  String message = data['message'] ?? "No details";
                  Timestamp? time = data['timestamp'];

                  IconData icon = Icons.notifications_active;
                  Color color = Colors.blue;
                  Color bgColor = Colors.blue[50]!;
                  String title = "Update";

                  if (message.toLowerCase().contains("delay") || message.toLowerCase().contains("breakdown")) {
                    icon = Icons.warning_amber_rounded;
                    color = Colors.orange;
                    bgColor = Colors.orange[50]!;
                    title = "Travel Alert";
                  } else if (message.toLowerCase().contains("cancel")) {
                    icon = Icons.cancel;
                    color = Colors.red;
                    bgColor = Colors.red[50]!;
                    title = "Cancelled";
                  }

                  return _buildNotificationCard(
                    icon, color, title, message, _formatTimestamp(time), bgColor
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("No active alerts", style: TextStyle(color: Colors.grey[500])),
          Text("Book a bus to see updates here.", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(IconData icon, Color iconColor, String title, String description, String time, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}