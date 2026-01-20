import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // Back arrow එක අයින් කරන්න
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildNotificationCard(
              Icons.directions_bus, Colors.blue, "Bus KY-1234 Delayed", "Your bus will arrive 10 minutes late due to traffic.", "10 minutes ago", Colors.blue[50]!
            ),
            _buildNotificationCard(
              Icons.check_circle, Colors.green, "Booking Confirmed", "Your seat A4 has been confirmed for Kandy to Colombo.", "2 hours ago", Colors.green[50]!
            ),
            _buildNotificationCard(
              Icons.location_on, Colors.orange, "Route Change", "Bus CM-5678 route has been changed due to road construction.", "Yesterday", Colors.orange[50]!
            ),
            _buildNotificationCard(
              Icons.warning, Colors.red, "Weather Alert", "Heavy rain expected on your route. Please plan accordingly.", "2 days ago", Colors.red[50]!
            ),
          ],
        ),
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