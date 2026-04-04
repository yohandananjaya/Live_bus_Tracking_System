import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatelessWidget {
  final String busId;
  const TripHistoryScreen({super.key, required this.busId});

  // --- දවසේ ආදායම මකන Function එක ---
  Future<void> _deleteItem(String docId) async {
    await FirebaseFirestore.instance.collection('buses').doc(busId).collection('trip_history').doc(docId).delete();
  }

  Future<void> _clearAll(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Revenue History?"),
        content: const Text("This cannot be undone. (Note: Admin Payouts will not be deleted)"),
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
    return DefaultTabController(
      length: 2, // 🔥 Tabs 2ක් හැදුවා
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Financials"),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Trip Revenue", icon: Icon(Icons.account_balance_wallet)),
              Tab(text: "Admin Payouts", icon: Icon(Icons.account_balance)), // 🔥 අලුත් Tab එක
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _clearAll(context),
              tooltip: "Clear Revenue History",
            )
          ],
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: Trip Revenue (පරණ එක) ---
            StreamBuilder<QuerySnapshot>(
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

            // --- TAB 2: Admin Payouts (අලුත් එක) ---
            StreamBuilder<QuerySnapshot>(
              // 🔥 Admin ගේ Payouts Collection එකෙන් ගන්නවා
              stream: FirebaseFirestore.instance
                  .collection('payouts')
                  .where('busId', isEqualTo: busId)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No payouts received yet", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    double amount = (data['amountTransferred'] ?? 0).toDouble();
                    String status = data['status'] ?? 'settled';
                    String refNo = data['referenceNo'] ?? 'N/A';
                    Timestamp? time = data['date'];
                    String dateStr = time != null ? DateFormat('MMM dd, yyyy').format(time.toDate()) : "Unknown Date";

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                          child: Icon(Icons.account_balance, color: Colors.blue[800]),
                        ),
                        title: Text("Rs. $amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800])),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Ref: $refNo", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Transferred on: $dateStr"),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(15)),
                          child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}