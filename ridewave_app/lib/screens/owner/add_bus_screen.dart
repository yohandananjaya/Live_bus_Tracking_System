import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // User ID එක ගන්න

class AddBusScreen extends StatefulWidget {
  // Edit කරනවා නම්, බස් එකේ ID එක සහ Data ටික මෙතනින් එනවා
  final String? busId;
  final Map<String, dynamic>? busData;

  const AddBusScreen({super.key, this.busId, this.busData});

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  // Controllers
  final _busNumberController = TextEditingController();
  final _busNameController = TextEditingController();
  final _permitNumberController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  final _stopsController = TextEditingController();
  final _seatCountController = TextEditingController();

  // Variables
  String _selectedBusType = 'Normal (Non-AC)';
  final List<String> _busTypes = ['Normal (Non-AC)', 'Semi-Luxury', 'Luxury (AC)', 'Super Luxury'];
  TimeOfDay _departureTime = TimeOfDay.now();
  bool _hasWifi = false;
  bool _hasCharging = false;
  bool _hasAdjustableSeats = false;
  List<String> _stops = [];
  bool _isLoading = false;

  // තෝරාගත් ෆොටෝ එක
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // EDIT MODE: ඩේටා එවලා තියෙනවා නම්, ඒවා ෆෝම් එකට පුරවනවා
    if (widget.busData != null) {
      final data = widget.busData!;
      _busNumberController.text = data['busNo'] ?? '';
      _busNameController.text = data['name'] ?? '';
      _permitNumberController.text = data['permitNo'] ?? '';
      _fromController.text = data['routeFrom'] ?? '';
      _toController.text = data['routeTo'] ?? '';
      _priceController.text = data['price'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _seatCountController.text = data['seats'] ?? '';
      _selectedBusType = data['type'] ?? 'Normal (Non-AC)';
      
      // වෙලාව හදනවා
      if (data['departureTime'] != null) {
        final timeParts = data['departureTime'].split(':');
        if (timeParts.length == 2) {
          _departureTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
        }
      }

      // පහසුකම් සහ නැවතුම්
      final amenities = data['amenities'] as Map<String, dynamic>?;
      _hasWifi = amenities?['wifi'] ?? false;
      _hasCharging = amenities?['charging'] ?? false;
      _hasAdjustableSeats = amenities?['seats'] ?? false;
      _stops = List<String>.from(data['stops'] ?? []);
    }
  }

  // ගැලරි එකෙන් ෆොටෝ එකක් තෝරගන්න Function එක
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _departureTime);
    if (picked != null && picked != _departureTime) {
      setState(() => _departureTime = picked);
    }
  }

  void _addStop() {
    if (_stopsController.text.isNotEmpty) {
      setState(() {
        _stops.add(_stopsController.text.trim());
        _stopsController.clear();
      });
    }
  }

  // --- SAVE / UPDATE Function එක ---
  Future<void> _saveBus() async {
    if (_busNumberController.text.isEmpty || _busNameController.text.isEmpty || _fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    // අයිතිකරුගේ ID එක ගන්නවා (වැදගත්ම කොටස)
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: You must be logged in to add a bus.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // යවන ඩේටා ටික Map එකක් විදියට හදාගන්නවා
      final busDataMap = {
        'ownerId': currentUserId, // බස් එක අයිති කාටද කියලා සේව් කරනවා
        'busNo': _busNumberController.text.trim(),
        'name': _busNameController.text.trim(),
        'permitNo': _permitNumberController.text.trim(),
        'type': _selectedBusType,
        'routeFrom': _fromController.text.trim(),
        'routeTo': _toController.text.trim(),
        'departureTime': "${_departureTime.hour.toString().padLeft(2,'0')}:${_departureTime.minute.toString().padLeft(2,'0')}",
        'stops': _stops,
        'price': _priceController.text.trim(),
        'seats': _seatCountController.text.trim(),
        'contact': _contactController.text.trim(),
        'amenities': {
          'wifi': _hasWifi,
          'charging': _hasCharging,
          'seats': _hasAdjustableSeats,
        },
        'imageUrl': null, 
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.busId != null) {
        // --- UPDATE MODE ---
        await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update(busDataMap);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bus Updated Successfully!")));
      } else {
        // --- ADD MODE ---
        busDataMap['createdAt'] = FieldValue.serverTimestamp();
        busDataMap['status'] = 'Idle';
        busDataMap['latitude'] = 6.9344; // Default Colombo
        busDataMap['longitude'] = 79.8428;
        await FirebaseFirestore.instance.collection('buses').add(busDataMap);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bus Added Successfully!")));
      }

      if (mounted) Navigator.pop(context); // ආපහු Dashboard එකට
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.busId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Bus" : "Add New Bus", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Photo Upload Area ---
            const Text("Bus Photo", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_selectedImage!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 5),
                        Text("Tap to upload a photo", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
              ),
            ),
            
            const SizedBox(height: 25),

            // Basic Info
            const Text("Basic Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 15),
            _buildTextField("Bus Number (Plate)", "e.g., WP KY-1234", _busNumberController),
            const SizedBox(height: 15),
            _buildTextField("Bus Name", "e.g., Express Liner", _busNameController),
            const SizedBox(height: 15),
            _buildTextField("NTC Permit Number", "e.g., NTC-001-XXXX", _permitNumberController),
            const SizedBox(height: 15),
            
            // Bus Type Dropdown
            const Text("Bus Type", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBusType,
                  isExpanded: true,
                  items: _busTypes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (newValue) => setState(() => _selectedBusType = newValue!),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Route & Schedule
            const Text("Route & Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField("From", "e.g., Kandy", _fromController)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("To", "e.g., Colombo", _toController)),
              ],
            ),
            const SizedBox(height: 15),

            // Time Picker
            const Text("Departure Time", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')} ${_departureTime.period.name.toUpperCase()}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.access_time, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Stops
            const Text("Stops Along the Route", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stopsController,
                    decoration: InputDecoration(
                      hintText: "Add a stop",
                      filled: true, fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addStop,
                  child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: Colors.white)),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: _stops.map((stop) => Chip(
                label: Text(stop), backgroundColor: Colors.blue[50], labelStyle: const TextStyle(color: Colors.blue),
                deleteIcon: const Icon(Icons.close, size: 18, color: Colors.blue),
                onDeleted: () => setState(() => _stops.remove(stop)),
              )).toList(),
            ),

            const SizedBox(height: 25),

            // Pricing & Features
            const Text("Pricing & Features", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField("Seat Count", "45", _seatCountController, isNumber: true)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Ticket Price (Rs)", "1500", _priceController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField("Contact Number", "+94 7X XXX XXXX", _contactController, isNumber: true),
            const SizedBox(height: 15),
            
            // Amenities
            const Text("Amenities", style: TextStyle(fontWeight: FontWeight.w500)),
            CheckboxListTile(
              title: const Text("Free Wi-Fi"), value: _hasWifi,
              onChanged: (val) => setState(() => _hasWifi = val!),
              controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text("USB Charging Ports"), value: _hasCharging,
              onChanged: (val) => setState(() => _hasCharging = val!),
              controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text("Adjustable Seats"), value: _hasAdjustableSeats,
              onChanged: (val) => setState(() => _hasAdjustableSeats = val!),
              controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBus,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditMode ? "Update Bus" : "Add Bus", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint, filled: true, fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
  }
}