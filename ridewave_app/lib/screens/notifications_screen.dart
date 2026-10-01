import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _clearAllNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    
    await prefs.setInt('lastClearedNotifs', now.millisecondsSinceEpoch);
    
    setState(() {
      _lastClearedTime = now;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All notifications cleared"),
          behavior: SnackBarBehavior.floating,
        ),
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
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: Text("Please Login to see alerts", style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Alerts",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Your travel updates",
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text("Clear Notifications?"),
                          content: const Text("This will hide all current alerts and updates.", style: TextStyle(color: Colors.black87)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _clearAllNotifications();
                              }, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                              ),
                              child: const Text("Clear All", style: TextStyle(fontWeight: FontWeight.bold))
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 5),
                          Text("Clear", style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // Content Body
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: user.uid)
                    .where('status', whereIn: ['confirmed', 'upcoming']) 
                    .snapshots(),
                builder: (context, bookingSnapshot) {
                  if (bookingSnapshot.hasError) return const Center(child: Text("Error loading data"));
                  if (bookingSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  if (!bookingSnapshot.hasData || bookingSnapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  List<String> activeBusIds = bookingSnapshot.data!.docs
                      .map((doc) => doc['busId'] as String)
                      .toSet()
                      .toList();

                  if (activeBusIds.isEmpty) return _buildEmptyState();

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('busId', whereIn: activeBusIds)
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

                      var allDocs = notifSnapshot.data!.docs;
                      var filteredDocs = allDocs.where((doc) {
                        if (_lastClearedTime == null) return true;
                        Timestamp? t = doc['timestamp'];
                        if (t == null) return true;
                        return t.toDate().isAfter(_lastClearedTime!);
                      }).toList();

                      if (filteredDocs.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var data = filteredDocs[index].data() as Map<String, dynamic>;
                          
                          String message = data['message'] ?? "No details";
                          Timestamp? time = data['timestamp'];

                          IconData icon = Icons.notifications_active_rounded;
                          Color color = Colors.blue[600]!;
                          Color bgColor = Colors.blue[50]!;
                          String title = "Update";

                          if (message.toLowerCase().contains("delay") || message.toLowerCase().contains("breakdown")) {
                            icon = Icons.warning_rounded;
                            color = Colors.orange[700]!;
                            bgColor = Colors.orange[50]!;
                            title = "Travel Alert";
                          } else if (message.toLowerCase().contains("cancel")) {
                            icon = Icons.cancel_rounded;
                            color = Colors.red[700]!;
                            bgColor = Colors.red[50]!;
                            title = "Cancelled";
                          }

                          return _buildPremiumNotificationCard(
                            icon, color, title, message, _formatTimestamp(time), bgColor
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_rounded, size: 60, color: Colors.blue[200]),
          ),
          const SizedBox(height: 20),
          const Text("You're all caught up!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text("No active alerts for your current rides.", style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPremiumNotificationCard(IconData icon, Color color, String title, String description, String time, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color indicator bar
            Container(width: 5, color: color),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                              Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}