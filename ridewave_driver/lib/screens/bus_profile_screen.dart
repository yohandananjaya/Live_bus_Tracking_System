import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusProfileScreen extends StatelessWidget {
  final String busId;
  const BusProfileScreen({super.key, required this.busId});

  void _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('busId');
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Bus Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.data!.exists) {
            return const Center(child: Text("Bus details not found"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          String busNo = data['busNo'] ?? "Unknown Bus";
          String model = data['model'] ?? "N/A";
          String capacity = data['capacity']?.toString() ?? "N/A";
          String routeFrom = data['routeFrom'] ?? "Not Set";
          String routeTo = data['routeTo'] ?? "Not Set";
          String price = data['price']?.toString() ?? "0";
          String status = data['status'] ?? "Offline";
          double rating = (data['rating'] ?? 0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar / Image placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[100],
                    border: Border.all(color: Colors.blue[800]!, width: 4),
                  ),
                  child: Center(
                    child: Icon(Icons.directions_bus_filled_rounded, size: 60, color: Colors.blue[800]),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  busNo,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Live' ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status == 'Live' ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Info Cards
                _buildInfoCard("Bus Model", model, Icons.bus_alert_rounded),
                _buildInfoCard("Seat Capacity", "$capacity Seats", Icons.event_seat_rounded),
                _buildInfoCard("Primary Route", "$routeFrom - $routeTo", Icons.route_rounded),
                _buildInfoCard("Ticket Price", "Rs. $price", Icons.monetization_on_rounded),
                _buildInfoCard("Average Rating", "$rating / 5.0", Icons.star_rounded, iconColor: Colors.amber),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {Color iconColor = Colors.blue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
