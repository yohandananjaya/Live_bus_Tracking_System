import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'search_ride_screen.dart'; 
import 'select_seat_screen.dart'; 
import 'emergency_screen.dart';
import 'report_issue_screen.dart';
import 'profile_screen.dart'; // 🔥 Profile Screen එක මෙතනට Import කරලා තියෙන්නේ

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchFrom = "";
  String _searchTo = "";

  // දුර සහ පැමිණීමට ගතවන කාලය ගණනය කරන Function එක
  Future<void> _showArrivalEstimate(BuildContext context, Map<String, dynamic> busData) async {
    double busLat = (busData['latitude'] ?? 0.0).toDouble();
    double busLng = (busData['longitude'] ?? 0.0).toDouble();

    if (busLat == 0.0 || busLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bus location not available yet.")));
      return;
    }

    try {
      Position userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double distanceInMeters = Geolocator.distanceBetween(userPosition.latitude, userPosition.longitude, busLat, busLng);
      double distanceInKm = distanceInMeters / 1000;
      double timeInHours = distanceInKm / 40.0; 
      int timeInMinutes = (timeInHours * 60).round();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.location_on, color: Colors.red), SizedBox(width: 10), Text("Live Status")]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(Icons.directions_bus, "Bus is", "${distanceInKm.toStringAsFixed(1)} km away"),
                const SizedBox(height: 15),
                _buildInfoRow(Icons.timer, "Arriving in", "$timeInMinutes mins"),
                const SizedBox(height: 10),
                const Text("(Estimated based on traffic)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enable GPS: $e")));
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.blue[800], size: 20)),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 1. BLUE BACKGROUND
          Container(
            height: 300, 
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[900]!, Colors.blue[700]!], 
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. SCROLLABLE CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10), 
                  
                  // 🔥 HEADER ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 40),
                          const SizedBox(width: 10),
                          const Text(
                            "RideWave", 
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 36, 
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      // 🔥 RIGHT: Profile Icon (Clickable)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  const Text("Where are you going?", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 25),

                  // 1. LIVE SEARCH BOX
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) => setState(() => _searchFrom = value.toLowerCase().trim()),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.my_location, color: Colors.blue),
                            hintText: "From (Start Location)",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none, contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const Divider(height: 30, thickness: 1), 
                        TextField(
                          onChanged: (value) => setState(() => _searchTo = value.toLowerCase().trim()),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.location_on, color: Colors.red),
                            hintText: "To (Destination)",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none, contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2. QUICK ACTIONS
                  Row(
                    children: [
                      Expanded(child: _buildQuickActionCard(context, Icons.calendar_month_rounded, "Book Seat", Colors.blue[800]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchRideScreen())))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildQuickActionCard(context, Icons.report_problem_rounded, "Report", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssueScreen())))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildQuickActionCard(context, Icons.sos_rounded, "SOS", Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyScreen())))),
                    ],
                  ),

                  const SizedBox(height: 30),
                  
                  // 3. LIVE NOW HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Live Buses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.red),
                            SizedBox(width: 5),
                            Text("Real-time", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 4. LIVE BUS LIST (With Updated Filtering Logic & Stops array)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('buses')
                        .where('status', isEqualTo: 'Live')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 30),
                              Icon(Icons.directions_bus_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              const Text("No live buses available", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      var buses = snapshot.data!.docs;

                      // Filtering logic
                      var filteredBuses = buses.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        
                        // 1. Data Lowercase කිරීම
                        String routeFrom = (data['routeFrom'] ?? '').toString().toLowerCase();
                        String routeTo = (data['routeTo'] ?? '').toString().toLowerCase();
                        
                        // 2. අතරමැදි නැවතුම් (Stops)
                        List<dynamic> stopsList = data['stops'] ?? [];
                        List<String> stops = stopsList.map((s) => s.toString().toLowerCase()).toList();

                        // 3. Search Logic
                        bool matchFrom = _searchFrom.isEmpty || 
                                         routeFrom.contains(_searchFrom) || 
                                         stops.any((stop) => stop.contains(_searchFrom));

                        bool matchTo = _searchTo.isEmpty || 
                                       routeTo.contains(_searchTo) || 
                                       stops.any((stop) => stop.contains(_searchTo));

                        return matchFrom && matchTo;
                      }).toList();

                      if (filteredBuses.isEmpty) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("No buses found for this route.", style: TextStyle(color: Colors.grey)),
                        ));
                      }

                      return ListView.builder(
                        shrinkWrap: true, 
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredBuses.length,
                        itemBuilder: (context, index) {
                          var doc = filteredBuses[index];
                          var data = doc.data() as Map<String, dynamic>;
                          return _buildLiveBusCard(context, doc.id, data);
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildQuickActionCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))]),
        child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))]),
      ),
    );
  }

  Widget _buildLiveBusCard(BuildContext context, String busId, Map<String, dynamic> data) {
    String busNo = data['busNo'] ?? "Unknown";
    String route = "${data['routeFrom'] ?? '?'} - ${data['routeTo'] ?? '?'}";
    double price = double.tryParse(data['price'].toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), child: Icon(Icons.directions_bus, color: Colors.blue[800])),
        title: Text(busNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(route, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.map_rounded, color: Colors.green), onPressed: () => _showArrivalEstimate(context, data)),
            const SizedBox(width: 5),
            ElevatedButton(
              onPressed: () {
                 String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                 Navigator.push(context, MaterialPageRoute(builder: (context) => SelectSeatScreen(busId: busId, busName: busNo, price: price, selectedDate: todayStr)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5)),
              child: const Text("Book", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}