import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginWithCode() async {
    String enteredCode = _codeController.text.trim(); // හිස්තැන් අයින් කරයි

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the access code")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 Firebase එකේ buses collection එකෙන් accessCode එක හොයනවා
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('buses')
          .where('accessCode', isEqualTo: enteredCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // කේතය නිවැරදියි! බස් එකේ Document ID එක ගන්නවා
        String busId = snapshot.docs.first.id;

        // SharedPreferences වල සේව් කරනවා (ඇප් එක වැහුවත් ලොග් වෙලා ඉන්න)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDriverLoggedIn', true); // main.dart එකෙන් මේක බලනවා
        await prefs.setString('driverBusId', busId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Successful!", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
          
          // Dashboard එකට යවනවා
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dashboard(busId: busId)),
          );
        }
      } else {
        // කේතය වැරදියි
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid Access Code. Please check again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Modern UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[800]!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_bus_filled_rounded, size: 60, color: Colors.blue[800]),
              ),
              const SizedBox(height: 20),
              Text(
                "RideWave Driver",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.blue[900],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter the Access Code to continue",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Login Form Card
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1), 
                      blurRadius: 15, 
                      offset: const Offset(0, 5)
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _codeController,
                      label: "Driver Access Code (e.g. RW-5RK4)",
                      icon: Icons.qr_code_scanner, // අයිකන් එක වෙනස් කළා
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity, 
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loginWithCode, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ), 
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom TextField
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters, // ගහන අකුරු Auto Capital වෙනවා
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[800]!, width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}