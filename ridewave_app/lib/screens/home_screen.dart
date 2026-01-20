import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // දුර මනින්න
import 'select_seat_screen.dart';
import 'emergency_screen.dart';
import 'report_issue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Search සදහා Controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  String searchFrom = "";
  String searchTo = "";

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String name = currentUser?.displayName?.split(" ")[0] ?? "User";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hi $name 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text("Where are you going today?", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  CircleAvatar(backgroundColor: Colors.blue[100], child: const Icon(Icons.person, color: Colors.blue))
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Search Box (From & To)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                child: Column(
                  children: [
                    TextField(
                      controller: _fromController,
                      onChanged: (val) => setState(() => searchFrom = val),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.my_location, color: Colors.blue), hintText: "From (Location)", border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _toController,
                      onChanged: (val) => setState(() => searchTo = val),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on, color: Colors.red), hintText: "To (Destination)", border: InputBorder.none),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildActionButton(context, Icons.call, "Emergency", Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyScreen()))),
                _buildActionButton(context, Icons.report_problem, "Report Issue", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssueScreen()))),
              ]),
              
              const SizedBox(height: 30),
              
              // Filtered Bus List
              const Text("Available Buses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('buses').where('status', isEqualTo: 'Live').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var buses = snapshot.data!.docs;

                  // Client-side Filtering (Search Logic)
                  var filteredBuses = buses.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String routeFrom = (data['routeFrom'] ?? "").toString().toLowerCase();
                    String routeTo = (data['routeTo'] ?? "").toString().toLowerCase();

                    bool matchFrom = searchFrom.isEmpty || routeFrom.contains(searchFrom.toLowerCase());
                    bool matchTo = searchTo.isEmpty || routeTo.contains(searchTo.toLowerCase());

                    return matchFrom && matchTo;
                  }).toList();

                  if (filteredBuses.isEmpty) {
                    return const Center(child: Text("No buses found for this route.", style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    shrinkWrap: true, // Scroll View ඇතුලේ ලිස්ට් එකක් නිසා
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      var doc = filteredBuses[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildBusCard(context, doc.id, data);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action Button Widget
  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 30)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]));
  }

  // Bus Card & Distance Calculation Logic
  Widget _buildBusCard(BuildContext context, String busId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)),
                    child: Text(data['busNo'] ?? "Unknown", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  // --- NEW: Map Icon for Distance/Time ---
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.green),
                    onPressed: () => _showArrivalEstimate(context, data),
                  ),
                ],
              ),
              Text("Rs. ${data['price'] ?? 0}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(data['name'] ?? "Bus Name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(data['routeFrom'] ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              const Spacer(),
              Text(data['routeTo'] ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Select Seat එකට Bus ID එක සහ Booked Seats යවනවා
                List<String> bookedSeats = List<String>.from(data['bookedSeats'] ?? []);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => SelectSeatScreen(
                    busId: busId,
                    busName: data['name'] ?? "Bus",
                    route: "${data['routeFrom']} - ${data['routeTo']}",
                    price: data['price'] ?? "0",
                    bookedSeats: bookedSeats
                  ))
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Select Seats", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Distance & Time Calculation Function ---
  Future<void> _showArrivalEstimate(BuildContext context, Map<String, dynamic> busData) async {
    // 1. බස් එකේ Location එක ගන්නවා
    double busLat = (busData['latitude'] ?? 0.0).toDouble();
    double busLng = (busData['longitude'] ?? 0.0).toDouble();

    if (busLat == 0.0 || busLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bus location not available yet.")));
      return;
    }

    // 2. මගේ Location එක ගන්නවා
    try {
      Position userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 3. දුර මනිනවා (Meters -> Kilometers)
      double distanceInMeters = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, busLat, busLng);
      double distanceInKm = distanceInMeters / 1000;

      // 4. වෙලාව මනිනවා (Average Speed 40km/h කියලා හිතමු)
      // Time = Distance / Speed
      double timeInHours = distanceInKm / 40.0; 
      int timeInMinutes = (timeInHours * 60).round();

      // 5. Dialog එක පෙන්නනවා
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Arrival Estimate"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus, size: 50, color: Colors.blue),
                const SizedBox(height: 10),
                Text("Distance: ${distanceInKm.toStringAsFixed(2)} km", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 5),
                Text("Est. Time: $timeInMinutes mins", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 10),
                const Text("(Assuming avg speed 40km/h)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
            ],
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
    }
  }
}