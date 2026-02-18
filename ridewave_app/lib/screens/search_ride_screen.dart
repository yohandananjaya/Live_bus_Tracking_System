import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[800]!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _searchBuses() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both locations")));
      return;
    }
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 1. BLUE HEADER BACKGROUND
          Container(
            height: 250,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[900]!, Colors.blue[700]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button & Title Row
                SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Plan Journey",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 15, top: 10),
                  child: Text(
                    "Book your seat in advance",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // 2. SCROLLABLE CONTENT (Card & Inputs)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 160, left: 20, right: 20), // Header එකට උඩින් පටන් ගන්න
              child: Column(
                children: [
                  
                  // --- INPUT CARD (FROM & TO) ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputField(_fromController, "From (Start)", Icons.my_location, Colors.blue),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildInputField(_toController, "To (Destination)", Icons.location_on, Colors.red),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- DATE SELECTOR ---
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.calendar_month_rounded, color: Colors.blue[800]),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Travel Date", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- SEARCH BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _searchBuses,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.blue.withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white),
                          SizedBox(width: 10),
                          Text("Search Buses", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tip Text
                  Text(
                    "Note: Enter exact city names (e.g. 'Colombo', 'Kandy')",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, Color iconColor) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: iconColor),
      ),
    );
  }
}