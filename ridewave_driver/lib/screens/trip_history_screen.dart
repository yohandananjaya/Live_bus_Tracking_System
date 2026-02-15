import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatelessWidget {
  final String busId;
  const TripHistoryScreen({super.key, required this.busId});

  // තනි Trip එකක් මකනවා
  Future<void> _deleteItem(String docId) async {
    await FirebaseFirestore.instance.collection('buses').doc(busId).collection('trip_history').doc(docId).delete();
  }

  // ඔක්කොම Clear කරනවා
  Future<void> _clearAll(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All History?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      var snapshots = await FirebaseFirestore.instance.collection('buses').doc(busId).collection('trip_history').get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Trip Revenue History"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _clearAll(context),
            tooltip: "Clear All",
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buses')
            .doc(busId)
            .collection('trip_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No trip history yet", style: TextStyle(color: Colors.grey[500])));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              double revenue = (data['revenue'] ?? 0).toDouble();
              Timestamp? time = data['timestamp'];
              String dateStr = time != null ? DateFormat('yyyy-MM-dd – hh:mm a').format(time.toDate()) : "Unknown Date";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[50],
                    child: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  title: Text("Rs. $revenue", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  subtitle: Text("Ended on: $dateStr"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteItem(doc.id),
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