import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // pubspec.yaml එකට intl දාන්න
import 'available_buses_screen.dart';

class SearchRideScreen extends StatefulWidget {
  const SearchRideScreen({super.key});

  @override
  State<SearchRideScreen> createState() => _SearchRideScreenState();
}

class _SearchRideScreenState extends State<SearchRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Date Picker එක පෙන්වන්න
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)), // දවස් 7ක් විතරක් දෙනවා
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _searchBuses() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter locations")));
      return;
    }

    // ඊළඟ පිටුවට යනවා (තෝරපු දත්ත අරගෙන)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableBusesScreen(
          from: _fromController.text.trim(),
          to: _toController.text.trim(),
          date: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find a Ride"), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _fromController, decoration: const InputDecoration(labelText: "From (Start)", prefixIcon: Icon(Icons.my_location), border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _toController, decoration: const InputDecoration(labelText: "To (Destination)", prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            // Date Selector
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[400]!)),
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text("Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _pickDate,
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _searchBuses,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                child: const Text("Search Buses", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}