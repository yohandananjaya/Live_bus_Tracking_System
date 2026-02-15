import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeTableScreen extends StatefulWidget {
  final String busId;
  const TimeTableScreen({super.key, required this.busId});

  @override
  State<TimeTableScreen> createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  // Time Table එකක් Add කරන Popup එක
  void _addOrEditTimeSlot(BuildContext context, {String? docId, String? start, String? end, String? sTime, String? eTime}) {
    final startLocCtrl = TextEditingController(text: start ?? "");
    final endLocCtrl = TextEditingController(text: end ?? "");
    final startTimeCtrl = TextEditingController(text: sTime ?? "");
    final endTimeCtrl = TextEditingController(text: eTime ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(docId == null ? "Add Schedule" : "Edit Schedule"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: startLocCtrl, decoration: const InputDecoration(labelText: "From (Start Location)")),
              TextField(controller: startTimeCtrl, decoration: const InputDecoration(labelText: "Departure Time (e.g. 10:30 AM)")),
              const SizedBox(height: 10),
              TextField(controller: endLocCtrl, decoration: const InputDecoration(labelText: "To (End Location)")),
              TextField(controller: endTimeCtrl, decoration: const InputDecoration(labelText: "Arrival Time (e.g. 11:30 AM)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
            onPressed: () async {
              Map<String, dynamic> data = {
                'startLocation': startLocCtrl.text,
                'endLocation': endLocCtrl.text,
                'startTime': startTimeCtrl.text,
                'endTime': endTimeCtrl.text,
                'timestamp': FieldValue.serverTimestamp(), // Sort කරන්න
              };

              if (docId == null) {
                // Add New
                await FirebaseFirestore.instance.collection('buses').doc(widget.busId).collection('timetable').add(data);
              } else {
                // Update Existing
                await FirebaseFirestore.instance.collection('buses').doc(widget.busId).collection('timetable').doc(docId).update(data);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _deleteSlot(String docId) {
    FirebaseFirestore.instance.collection('buses').doc(widget.busId).collection('timetable').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Bus Time Table"), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        onPressed: () => _addOrEditTimeSlot(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').doc(widget.busId).collection('timetable').orderBy('startTime').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No schedule added yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Row(
                    children: [
                      Icon(Icons.departure_board, size: 18, color: Colors.blue[800]),
                      const SizedBox(width: 5),
                      Text("${data['startTime']} - ${data['startLocation']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 18, color: Colors.red[800]),
                        const SizedBox(width: 5),
                        Text("${data['endTime']} - ${data['endLocation']}"),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _addOrEditTimeSlot(context, docId: doc.id, start: data['startLocation'], end: data['endLocation'], sTime: data['startTime'], eTime: data['endTime'])),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSlot(doc.id)),
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
}