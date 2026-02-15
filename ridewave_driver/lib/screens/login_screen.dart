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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCodeVerified = false;
  bool _isFirstTime = false;
  String? _busId;
  String? _busName;

  // --- Logic එහෙම්මමයි ---
  Future<void> _verifyCode() async {
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

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDriverLoggedIn', true);
      await prefs.setString('driverBusId', _busId!);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Dashboard(busId: _busId!)),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
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
                "Welcome back! Please login to continue.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Login Form Card
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    if (!_isCodeVerified) ...[
                      _buildTextField(
                        controller: _codeController,
                        label: "Driver Code",
                        icon: Icons.qr_code,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity, 
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ), 
                          child: const Text("Verify Code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    if (_isCodeVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue[800]),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Bus: $_busName", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900]))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(controller: _passwordController, label: "Password", icon: Icons.lock, isObscure: true),
                      if (_isFirstTime) ...[
                        const SizedBox(height: 15),
                        _buildTextField(controller: _confirmPasswordController, label: "Confirm Password", icon: Icons.lock_outline, isObscure: true),
                      ],
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity, 
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _processLogin, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600], // Green for login action
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ), 
                          child: Text(_isFirstTime ? "Set Password & Login" : "Login", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
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