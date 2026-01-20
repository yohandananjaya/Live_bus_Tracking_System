import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // User ID එක ගන්න
import 'add_bus_screen.dart';
import '../../services/location_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final LocationService _locationService = LocationService();
  // දැනට ලොග් වී සිටින User ගේ ID එක
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  void _toggleTrip(String busId, bool currentStatus) async {
    if (currentStatus) {
      await FirebaseFirestore.instance.collection('buses').doc(busId).update({'status': 'Idle'});
      await _locationService.stopTrip();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Ended")));
    } else {
      if (_locationService.isTripActive) {
        await _locationService.stopTrip();
      }
      bool started = await _locationService.startTrip(busId);
      if (started) {
        await FirebaseFirestore.instance.collection('buses').doc(busId).update({'status': 'Live'});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Started!")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission denied")));
      }
    }
  }

  void _deleteBus(String busId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Bus"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('buses').doc(busId).delete();
            if (mounted) Navigator.pop(context);
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Owner Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBusScreen())),
                icon: const Icon(Icons.add), label: const Text("Add New Bus"),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // --- වෙනස් කළ කොටස ---
                // මෙතනින් කියන්නේ 'ownerId' එක මගේ ID එකට සමාන ඒවා විතරක් දෙන්න කියලා
                stream: FirebaseFirestore.instance
                    .collection('buses')
                    .where('ownerId', isEqualTo: currentUserId) 
                    .snapshots(),
                // ---------------------
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("You haven't added any buses yet."));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      bool isLive = data['status'] == 'Live';
                      return Card(
                        child: ListTile(
                          title: Text(data['busNo'] ?? 'Unknown'),
                          subtitle: Text(data['name'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _toggleTrip(doc.id, isLive),
                                style: ElevatedButton.styleFrom(backgroundColor: isLive ? Colors.red : Colors.green),
                                child: Text(isLive ? "Stop" : "Start", style: const TextStyle(color: Colors.white)),
                              ),
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddBusScreen(busId: doc.id, busData: data)))),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBus(doc.id)),
                            ],
                          ),
                        ),
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
}