import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Session manage කරන්න
import '../../services/location_service.dart'; // Location Service
import '../login_screen.dart'; // Logout වුනාම යන්න
import 'driver_seat_view.dart';
import 'driver_bookings_screen.dart';
import 'driver_report_screen.dart';

class DriverDashboard extends StatefulWidget {
  final String busId;
  const DriverDashboard({super.key, required this.busId});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;

  // --- 1. Logout Function ---
  Future<void> _handleLogout(bool isLive) async {
    // Confirm Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout? \n(Active trips will be stopped)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      // Trip එක Active නම් නවත්වනවා
      if (isLive) {
        await _locationService.stopTrip();
        await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({'status': 'Idle'});
      }

      // ** Shared Preferences වලින් Login Data මකනවා **
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isDriverLoggedIn');
      await prefs.remove('driverBusId');

      if (mounted) {
        // Login Screen එකට යනවා (Back එන්න බැරි විදියට History එක මකලා)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // --- 2. Price Edit Function ---
  void _editTicketPrice(BuildContext context, String currentPrice) {
    TextEditingController priceController = TextEditingController(text: currentPrice);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Ticket Price"),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "New Price (Rs.)", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({
                'price': priceController.text.trim()
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  // --- 3. Trip Start/Stop Logic ---
  void _toggleTripStatus(bool isCurrentlyLive) async {
    setState(() => _isLoading = true);
    if (isCurrentlyLive) {
      // Stop Trip
      await _locationService.stopTrip();
      // (Location Service එක ඇතුලෙම status update වෙනවා, නමුත් ආරක්ෂාවට මෙතනත් කරනවා)
      await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({'status': 'Idle'});
    } else {
      // Start Trip
      bool started = await _locationService.startTrip(widget.busId);
      if (started) {
        await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({'status': 'Live'});
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GPS Permission Denied")));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // PopScope අයින් කළා. දැන් Back ගැහුවම App එක Minimize වෙනවා (Login එකට යන්නේ නෑ).
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false, // Back Arrow එක අයින් කරනවා
        actions: [
          // Report Button
          IconButton(
            icon: const Icon(Icons.report_problem, color: Colors.white),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverReportScreen()));
            },
          ),
          // Logout Button with Confirmation
          StreamBuilder<DocumentSnapshot>(
             stream: FirebaseFirestore.instance.collection('buses').doc(widget.busId).snapshots(),
             builder: (context, snapshot) {
               bool isLive = false;
               if(snapshot.hasData && snapshot.data!.data() != null) {
                 var d = snapshot.data!.data() as Map<String, dynamic>;
                 isLive = d['status'] == 'Live';
               }
               return IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _handleLogout(isLive),
               );
             }
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').doc(widget.busId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.data!.exists) return const Center(child: Text("Bus Data Not Found"));

          var data = snapshot.data!.data() as Map<String, dynamic>;
          bool isLive = data['status'] == 'Live';
          String price = data['price'] ?? "0";
          
          // Revenue එක පරිස්සමෙන් ගන්න (int ද double ද කියලා බලලා)
          double totalRevenue = 0.0;
          if (data['totalRevenue'] != null) {
            totalRevenue = (data['totalRevenue'] is int) 
                ? (data['totalRevenue'] as int).toDouble() 
                : (data['totalRevenue'] as double);
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. Bus Info Card
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus, size: 40, color: Colors.blue),
                    title: Text(data['busNo'] ?? "Bus No", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['routeFrom']} - ${data['routeTo']}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text(isLive ? "LIVE" : "IDLE", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // 2. Revenue & Price Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard("Total Revenue", "Rs. ${totalRevenue.toStringAsFixed(2)}", Colors.green, null),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoCard("Ticket Price", "Rs. $price", Colors.orange, () => _editTicketPrice(context, price)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Navigation Buttons
                _buildNavButton(Icons.grid_on, "View Seat Layout", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DriverSeatView(busId: widget.busId)));
                }),
                const SizedBox(height: 10),
                _buildNavButton(Icons.confirmation_number, "Manage Bookings", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DriverBookingsScreen(busId: widget.busId, ticketPrice: price)));
                }),

                const Spacer(),

                // 4. Start/Stop Trip Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _toggleTripStatus(isLive),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    icon: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(isLive ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      isLive ? "END TRIP" : "START TRIP", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInfoCard(String title, String value, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                if (onTap != null) const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(Icons.edit, size: 16, color: Colors.grey),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}