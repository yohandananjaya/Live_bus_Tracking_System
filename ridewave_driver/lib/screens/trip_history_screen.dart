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
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Financials", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () => _clearAll(context),
              tooltip: "Clear Revenue History",
            )
          ],
        ),
        body: Stack(
          children: [
            // --- 1. Background Image Header ---
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.35,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/bus_nine_arches.jpg'), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.3)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const TabBar(
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: "Trip Revenue", icon: Icon(Icons.account_balance_wallet)),
                          Tab(text: "Admin Payouts", icon: Icon(Icons.account_balance)),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // --- 2. Sliding White Container for Content ---
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // --- TAB 1: Trip Revenue ---
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
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.history, size: 60, color: Colors.grey[300]),
                                      const SizedBox(height: 10),
                                      Text("No trip history yet", style: TextStyle(color: Colors.grey[500])),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var doc = snapshot.data!.docs[index];
                                  var data = doc.data() as Map<String, dynamic>;
                                  double revenue = (data['revenue'] ?? 0).toDouble();
                                  Timestamp? time = data['timestamp'];
                                  String dateStr = time != null ? DateFormat('yyyy-MM-dd – hh:mm a').format(time.toDate()) : "Unknown Date";

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(bottom: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                        child: const Icon(Icons.attach_money, color: Colors.green),
                                      ),
                                      title: Text("Rs. $revenue", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                      subtitle: Text("Ended on: $dateStr", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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

                          // --- TAB 2: Admin Payouts ---
                          StreamBuilder<QuerySnapshot>(
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
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                    margin: const EdgeInsets.only(bottom: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                        child: Icon(Icons.account_balance, color: Colors.blue[800]),
                                      ),
                                      title: Text("Rs. $amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800])),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 5),
                                          Text("Ref: $refNo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 12)),
                                          Text("Transferred on: $dateStr", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
