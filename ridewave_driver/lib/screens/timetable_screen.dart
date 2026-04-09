import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TimeTableScreen extends StatefulWidget {
  final String busId;
  const TimeTableScreen({super.key, required this.busId});

  @override
  State<TimeTableScreen> createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  String _selectedDay = 'Monday'; 

  // --- අලුත් Schedule එකක් Add කිරීම (Auto Price Calculation) ---
  void _addOrEditTimeSlot(BuildContext context, {String? docId, String? start, String? end, String? sTime}) {
    final startLocCtrl = TextEditingController(text: start ?? "");
    final endLocCtrl = TextEditingController(text: end ?? "");
    final startTimeCtrl = TextEditingController(text: sTime ?? "");
    bool isCalculating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(docId == null ? "Add Schedule for $_selectedDay" : "Edit Schedule"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: startLocCtrl, decoration: const InputDecoration(labelText: "From (Start Location)", hintText: "e.g. Colombo")),
                  TextField(controller: endLocCtrl, decoration: const InputDecoration(labelText: "To (Destination)", hintText: "e.g. Kandy")),
                  const SizedBox(height: 10),
                  TextField(controller: startTimeCtrl, decoration: const InputDecoration(labelText: "Departure Time", hintText: "e.g. 08:30 AM")),
                  const SizedBox(height: 15),
                  const Text(
                    "Ticket price will be auto-calculated based on distance and current Admin rates.", 
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)
                  ),
                  if (isCalculating) const Padding(padding: EdgeInsets.only(top: 15), child: CircularProgressIndicator()),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isCalculating ? null : () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                onPressed: isCalculating ? null : () async {
                  if (startLocCtrl.text.isEmpty || endLocCtrl.text.isEmpty || startTimeCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }

                  setDialogState(() => isCalculating = true);

                  try {
                    DocumentSnapshot settingsDoc = await FirebaseFirestore.instance.collection('settings').doc('pricing').get();
                    double basePrice = 27.0; 
                    double ratePerKm = 5.0;  
                    
                    if (settingsDoc.exists) {
                      var data = settingsDoc.data() as Map<String, dynamic>;
                      basePrice = (data['baseFare'] ?? 27.0).toDouble();
                      ratePerKm = (data['perKmRate'] ?? 5.0).toDouble();
                    }

                    List<Location> fromLocations = await locationFromAddress("${startLocCtrl.text}, Sri Lanka");
                    List<Location> toLocations = await locationFromAddress("${endLocCtrl.text}, Sri Lanka");

                    double distanceInMeters = Geolocator.distanceBetween(
                      fromLocations.first.latitude, fromLocations.first.longitude,
                      toLocations.first.latitude, toLocations.first.longitude,
                    );
                    double distanceInKm = distanceInMeters / 1000;

                    int finalPrice = (basePrice + (distanceInKm * ratePerKm)).round();

                    Map<String, dynamic> scheduleData = {
                      'busId': widget.busId,
                      'dayOfWeek': _selectedDay,
                      'routeFrom': startLocCtrl.text.trim(),
                      'routeTo': endLocCtrl.text.trim(),
                      'departureTime': startTimeCtrl.text.trim(),
                      'price': finalPrice, 
                      'timestamp': FieldValue.serverTimestamp(),
                    };

                    if (docId == null) {
                      await FirebaseFirestore.instance.collection('schedules').add(scheduleData);
                    } else {
                      await FirebaseFirestore.instance.collection('schedules').doc(docId).update(scheduleData);
                    }

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved! Ticket Price: Rs. $finalPrice"), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setDialogState(() => isCalculating = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error calculating route. Try valid city names."), backgroundColor: Colors.red));
                  }
                },
                child: const Text("Calculate & Save", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      ),
    );
  }

  void _deleteSlot(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Schedule"),
        content: const Text("Are you sure you want to delete this trip from the schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection('schedules').doc(docId).delete();
              Navigator.pop(ctx);
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Weekly Schedule"), 
        backgroundColor: Colors.blue[800], 
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue[800],
        onPressed: () => _addOrEditTimeSlot(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Trip", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                String day = _weekDays[index];
                bool isSelected = _selectedDay == day;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Colors.blue[800]! : Colors.transparent, 
                          width: 3
                        )
                      )
                    ),
                    child: Text(
                      day, 
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue[800] : Colors.grey[600],
                        fontSize: 16
                      )
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('busId', isEqualTo: widget.busId)
                  .where('dayOfWeek', isEqualTo: _selectedDay)
                  .orderBy('departureTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No trips scheduled for $_selectedDay.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                              child: Text(data['departureTime'] ?? "--:--", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 16)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${data['routeFrom']} to ${data['routeTo']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 5),
                                  Text("Ticket: Rs. ${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _addOrEditTimeSlot(context, docId: doc.id, start: data['routeFrom'], end: data['routeTo'], sTime: data['departureTime']);
                                } else if (value == 'delete') {
                                  _deleteSlot(doc.id);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text("Edit")])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text("Delete")])),
                              ],
                            ),
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
    );
  }
}