import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'select_seat_screen.dart'; // ඊළඟ පියවරේ හදන එක

class AvailableBusesScreen extends StatelessWidget {
  final String from;
  final String to;
  final DateTime date;

  const AvailableBusesScreen({super.key, required this.from, required this.to, required this.date});

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);

    return Scaffold(
      appBar: AppBar(title: Text("Buses on $dateStr"), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        // Route එකට ගැලපෙන බස් ටික හොයනවා
        // (සැලකිය යුතුයි: Case Sensitive ප්‍රශ්න මගහරින්න හරියටම නම ගහන්න ඕනේ, නැත්නම් Dropdown දාන්න වෙනවා)
        stream: FirebaseFirestore.instance
            .collection('buses')
            .where('routeFrom', isEqualTo: from)
            .where('routeTo', isEqualTo: to)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No buses found for this route."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var busDoc = snapshot.data!.docs[index];
              var busData = busDoc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: const Icon(Icons.directions_bus, size: 40, color: Colors.blue),
                  title: Text(busData['busNo'] ?? "Bus", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Route: ${busData['routeFrom']} - ${busData['routeTo']}"),
                      Text("Price: Rs. ${busData['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Seat Select කරන්න යවනවා (දිනයත් අරගෙනම)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectSeatScreen(
                            busId: busDoc.id,
                            busName: busData['busNo'],
                            price: double.tryParse(busData['price'].toString()) ?? 0.0,
                            selectedDate: dateStr, // දිනය පාස් කරනවා
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("Book", style: TextStyle(color: Colors.white)),
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