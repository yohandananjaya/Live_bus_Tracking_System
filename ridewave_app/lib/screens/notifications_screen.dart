import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Save කරන්න ඕනේ

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  DateTime? _lastClearedTime;

  @override
  void initState() {
    super.initState();
    _loadLastClearedTime();
  }

  // 1. කලින් Clear කරපු වෙලාව Load කරගන්නවා
  Future<void> _loadLastClearedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? timestamp = prefs.getInt('lastClearedNotifs');
    if (timestamp != null) {
      if (mounted) {
        setState(() {
          _lastClearedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        });
      }
    }
  }

  // 2. Notifications Clear කරන Function එක
  Future<void> _clearAllNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    
    // දැනට තියෙන වෙලාව Save කරගන්නවා (මේ වෙලාවට කලින් ආපු ඒවා පෙන්වන්නේ නෑ)
    await prefs.setInt('lastClearedNotifs', now.millisecondsSinceEpoch);
    
    setState(() {
      _lastClearedTime = now;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notifications Cleared")),
      );
    }
  }

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
        // 🔥 Clear All Button එක මෙතනට දැම්මා
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded, color: Colors.red),
            tooltip: "Clear Notifications",
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Clear Notifications?"),
                  content: const Text("This will hide all current alerts."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearAllNotifications();
                      }, 
                      child: const Text("Clear", style: TextStyle(color: Colors.red))
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      // 3. Booking Query (Confirmed ඒවා විතරයි)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            // 🔥 වෙනස්කම: 'confirmed' සහ 'upcoming' විතරයි. (Pending අයින් කළා)
            .where('status', whereIn: ['confirmed', 'upcoming']) 
            .snapshots(),
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.hasError) return const Center(child: Text("Error loading data"));
          if (bookingSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // බුකින් නැත්නම්
          if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Active Bus IDs ටික ගන්නවා
          List<String> activeBusIds = bookingSnapshot.data!.docs
              .map((doc) => doc['busId'] as String)
              .toSet()
              .toList();

          if (activeBusIds.isEmpty) return _buildEmptyState();

          // 4. Notifications Query
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('busId', whereIn: activeBusIds) // අදාල බස් වලට විතරයි
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, notifSnapshot) {
              if (notifSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!notifSnapshot.hasData || notifSnapshot.data!.docs.isEmpty) {
                 return _buildEmptyState();
              }

              // 🔥 මෙතනදී අපි Clear කරපු වෙලාවට පස්සේ ආපු ඒවා විතරක් පෙරලා ගන්නවා
              var allDocs = notifSnapshot.data!.docs;
              var filteredDocs = allDocs.where((doc) {
                if (_lastClearedTime == null) return true; // කවදාවත් Clear කරලා නැත්නම් ඔක්කොම පෙන්වන්න
                Timestamp? t = doc['timestamp'];
                if (t == null) return true;
                return t.toDate().isAfter(_lastClearedTime!); // Clear කළාට පස්සේ ආපු ඒවා විතරයි
              }).toList();

              if (filteredDocs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  var data = filteredDocs[index].data() as Map<String, dynamic>;
                  
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