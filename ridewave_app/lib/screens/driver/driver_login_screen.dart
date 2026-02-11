import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import
import 'driver_dashboard.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  // ... (අනිත් Controllers ටික එහෙමම තියන්න) ...
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Confirm password controller එක දාන්න
  
  bool _isLoading = false;
  bool _isCodeVerified = false;
  bool _isFirstTime = false;
  String? _busId;
  String? _busName;

  // ... (_verifyCode Function එක එහෙමම තියන්න) ...
  Future<void> _verifyCode() async {
    // (Old code for verify - no change needed here)
     setState(() => _isLoading = true);
    try {
      var query = await FirebaseFirestore.instance
          .collection('buses')
          .where('driverCode', isEqualTo: _codeController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var data = query.docs.first.data();
        setState(() {
          _busId = query.docs.first.id;
          _busName = data['name'];
          _isFirstTime = (data['driverPassword'] == null || data['driverPassword'] == "");
          _isCodeVerified = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Driver Code")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Login Logic එක වෙනස් කරන්න
  Future<void> _processLogin() async {
    if (_passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isFirstTime) {
         if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
          setState(() => _isLoading = false);
          return;
        }
        await FirebaseFirestore.instance.collection('buses').doc(_busId).update({
          'driverPassword': _passwordController.text.trim(),
        });
      } else {
        var doc = await FirebaseFirestore.instance.collection('buses').doc(_busId).get();
        if (doc['driverPassword'] != _passwordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Password!")));
          setState(() => _isLoading = false);
          return;
        }
      }

      // --- SAVE SESSION Locally ---
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDriverLoggedIn', true);
      await prefs.setString('driverBusId', _busId!);

      // --- NAVIGATION FIX ---
      if (mounted) {
        // pushReplacement වෙනුවට pushAndRemoveUntil පාවිච්චි කරන්න.
        // මේකෙන් පස්සෙ තියෙන ඔක්කොම Screen මැකෙනවා. Back ගැහුවට Login එකට යන්නේ නෑ.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DriverDashboard(busId: _busId!)),
          (route) => false, // මෙය false කිරීමෙන් පසුබිමේ කිසිම පිටුවක් ඉතුරු වෙන්නේ නෑ
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ... (Build Method එක එහෙමම තියන්න) ...
  @override
  Widget build(BuildContext context) {
      // (UI Code එකේ වෙනසක් නෑ, කලින් එකමයි)
      return Scaffold(
      appBar: AppBar(title: const Text("Driver Partner Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus_filled, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            
            if (!_isCodeVerified) ...[
              const Text("Enter your Bus Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: "Driver Code", border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, 
                height: 50,
                child: ElevatedButton(onPressed: _isLoading ? null : _verifyCode, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: _isLoading ? const CircularProgressIndicator() : const Text("Verify Code", style: TextStyle(color: Colors.white))),
              ),
            ],

            if (_isCodeVerified) ...[
              Text("Bus: $_busName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 20),
              Text(_isFirstTime ? "Set New Password" : "Enter Password", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 10),
              if (_isFirstTime) TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(onPressed: _isLoading ? null : _processLogin, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(_isFirstTime ? "Save & Login" : "Login", style: const TextStyle(color: Colors.white, fontSize: 18))),
              ),
            ]
          ],
        ),
      ),
    );
  }
}