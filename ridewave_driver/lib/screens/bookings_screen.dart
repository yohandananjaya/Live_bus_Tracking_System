import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // pubspec.yaml එකට intl දාන්න

class BookingsScreen extends StatefulWidget {
  final String busId;
  const BookingsScreen({super.key, required this.busId});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  DateTime _selectedDate = DateTime.now(); // Default: අද දවස

  // දිනය තෝරාගැනීම
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Booking එක Confirm කිරීම
  Future<void> _confirm(String id, double price) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'confirmed'});
    // Note: Long distance වලදී Revenue එක Bus එකට කෙලින්ම එකතු කරනවද, 
    // නැත්නම් Trip එක අවසානයේ එකතු කරනවද කියලා තීරණය කරන්න ඕනේ. 
    // දැනට Confirm විතරක් කරමු.
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Confirmed!")));
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate, // දින දර්ශනය
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('busId', isEqualTo: widget.busId)
            .where('travelDate', isEqualTo: formattedDate) // 🔥 දිනයට අදාළ ඒවා විතරයි
            .where('status', whereIn: ['pending', 'upcoming', 'confirmed']) 
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No bookings for $formattedDate", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool confirmed = data['status'] == 'confirmed';
              List seats = data['seats'] ?? [];
              double price = (data['totalPrice'] is String) 
                  ? double.tryParse(data['totalPrice']) ?? 0.0 
                  : (data['totalPrice'] as num).toDouble();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: confirmed ? Colors.green[100] : Colors.orange[100],
                    child: Icon(Icons.person, color: confirmed ? Colors.green : Colors.orange),
                  ),
                  title: Text("Seats: ${seats.join(', ')}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Rs. $price  •  ${data['status'].toString().toUpperCase()}"),
                  trailing: confirmed 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.symmetric(horizontal: 10)),
                        onPressed: () => _confirm(doc.id, price),
                        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontSize: 12)),
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