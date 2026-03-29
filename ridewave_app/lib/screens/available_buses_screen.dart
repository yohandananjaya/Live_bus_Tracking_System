import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_seat_screen.dart'; 

class AvailableBusesScreen extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final String dayOfWeek; 
  final String selectedDate; 

  const AvailableBusesScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.dayOfWeek,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$fromLocation to $toLocation", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("$selectedDate ($dayOfWeek)", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. දවසට (dayOfWeek) අදාළ Schedules ඔක්කොම ගන්නවා
        stream: FirebaseFirestore.instance
            .collection('schedules')
            .where('dayOfWeek', isEqualTo: dayOfWeek)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoBusesUI();
          }

          // 2. ගත්තු Data ටික Local Filter කරනවා (Smart Search - Case Insensitive)
          var allSchedules = snapshot.data!.docs;
          var filteredSchedules = allSchedules.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            
            // Database එකේ තියෙන නම් සිම්පල් කරනවා
            String dbFrom = (data['routeFrom'] ?? '').toString().toLowerCase();
            String dbTo = (data['routeTo'] ?? '').toString().toLowerCase();
            
            // අපි ගහපු නම් සිම්පල් කරනවා
            String searchFrom = fromLocation.toLowerCase();
            String searchTo = toLocation.toLowerCase();

            // කොහොම හරි වචනේ තිබ්බොත් Match වෙනවා (e.g. 'hapugala' matches 'Galle to Hapugala')
            return dbFrom.contains(searchFrom) && dbTo.contains(searchTo);
          }).toList();

          // 3. වෙලාව අනුව Sort කරනවා
          filteredSchedules.sort((a, b) {
            String timeA = (a.data() as Map<String, dynamic>)['departureTime'] ?? '';
            String timeB = (b.data() as Map<String, dynamic>)['departureTime'] ?? '';
            return timeA.compareTo(timeB);
          });

          if (filteredSchedules.isEmpty) {
            return _buildNoBusesUI();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredSchedules.length,
            itemBuilder: (context, index) {
              var schedule = filteredSchedules[index];
              var data = schedule.data() as Map<String, dynamic>;

              String busId = data['busId'] ?? '';
              String busNo = data['routeFrom'] ?? 'Bus'; // Displaying route start instead of bus ID if not avail
              String time = data['departureTime'] ?? '--:--';
              double price = double.tryParse(data['price'].toString()) ?? 0.0;

              return Card(
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12), 
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), 
                                child: Icon(Icons.directions_bus_rounded, color: Colors.blue[800], size: 30)
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Departure", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  Text(time, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Ticket Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text("Rs. ${price.toInt()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
                            ],
                          )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
                      Row(
                        children: [
                          Icon(Icons.route, color: Colors.blue[300], size: 16),
                          const SizedBox(width: 10),
                          Text("${data['routeFrom']} to ${data['routeTo']}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800], 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectSeatScreen(
                                  busId: busId,
                                  busName: "Scheduled Bus", // Or fetch actual bus name if saved in schedule
                                  price: price,
                                  selectedDate: selectedDate, 
                                ),
                              ),
                            );
                          },
                          child: const Text("Select Seats", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
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

  Widget _buildNoBusesUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: Icon(Icons.event_busy, size: 60, color: Colors.blue[300]),
          ),
          const SizedBox(height: 20),
          Text(
            "No buses found for\n$fromLocation to $toLocation", 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          Text(
            "On $selectedDate ($dayOfWeek)", 
            style: TextStyle(color: Colors.grey[600])
          ),
        ],
      ),
    );
  }
}