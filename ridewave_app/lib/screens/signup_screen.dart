import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nameController.text.trim());
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(flex: 2, child: Center(child: Text("RideWave", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)))),
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      TextField(controller: _nameController, decoration: InputDecoration(labelText: "Full Name", prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 15),
                      TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 15),
                      TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 15),
                      TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: "Confirm Password", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 30),
                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _signUp, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)))),
                      const SizedBox(height: 20),
                      GestureDetector(onTap: () => Navigator.pop(context), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Already have an account? "), Text("Sign In", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))])),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}