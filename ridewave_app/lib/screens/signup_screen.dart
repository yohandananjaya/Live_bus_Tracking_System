import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _phoneController = TextEditingController(); // Phone number
  final _otpController = TextEditingController(); // OTP

  bool _isLoading = false;
  String? _verificationId;

  // 1. Start Phone Verification
  Future<void> _startPhoneVerification(Function onVerified) async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your phone number")));
      return;
    }
    if (!phone.startsWith('+')) {
      phone = '+94$phone'; // Default to Sri Lanka if no country code
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Android)
          onVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          _showOtpDialog(onVerified);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 2. Show OTP Dialog
  void _showOtpDialog(Function onVerified) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter OTP"),
          content: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "OTP Code"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                String otp = _otpController.text.trim();
                if (otp.isNotEmpty && _verificationId != null) {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!,
                    smsCode: otp,
                  );
                  onVerified(credential);
                }
              },
              child: const Text("Verify"),
            ),
          ],
        );
      },
    );
  }

  // 3. Normal Sign Up Flow
  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    
    // First verify phone
    await _startPhoneVerification((PhoneAuthCredential phoneCredential) async {
      try {
        setState(() => _isLoading = true);
        
        // Create user
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
          
          // Link phone if needed or just save to Firestore
          try {
            await userCredential.user!.linkWithCredential(phoneCredential);
          } catch(e) {
             print("Phone linking error (ignoring): $e");
          }

          // Save to Firestore
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    });
  }

  // 4. Google Sign Up Flow
  Future<void> _signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      setState(() => _isLoading = true);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if user already exists in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        // NEW USER: Needs phone verification
        // Show dialog to ask for phone number first
        _showPhoneInputDialog((phone) {
           _phoneController.text = phone;
           _startPhoneVerification((PhoneAuthCredential phoneCredential) async {
              setState(() => _isLoading = true);
              try {
                await userCredential.user!.linkWithCredential(phoneCredential);
              } catch(e) {}
              
              await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                'name': userCredential.user!.displayName ?? 'User',
                'email': userCredential.user!.email ?? '',
                'phone': _phoneController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
           });
        });
      } else {
        // Existing user, just login
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-Up Failed: $e")));
    }
  }

  // Dialog for Google Users to enter phone
  void _showPhoneInputDialog(Function(String) onSubmit) {
    TextEditingController tempPhoneCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Enter Phone Number"),
        content: TextField(
          controller: tempPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Phone Number (e.g. 771234567)", prefixText: "+94 "),
        ),
        actions: [
          TextButton(onPressed: () {
            FirebaseAuth.instance.signOut();
            GoogleSignIn().signOut();
            Navigator.pop(context);
          }, child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (tempPhoneCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                onSubmit("+94${tempPhoneCtrl.text.trim()}");
              }
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/home_bg.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logo.png', width: 80, height: 80),
                          const SizedBox(height: 10),
                          const Text("RideWave", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 7, // Increased flex to give more scroll space
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 30),
                          _buildTextField(_nameController, "Full Name", Icons.person_outline, false),
                          const SizedBox(height: 15),
                          _buildTextField(_emailController, "Email", Icons.email_outlined, false),
                          const SizedBox(height: 15),
                          _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined, false, inputType: TextInputType.phone),
                          const SizedBox(height: 15),
                          _buildTextField(_passwordController, "Password", Icons.lock_outline, true),
                          const SizedBox(height: 15),
                          _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_outline, true),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity, 
                            height: 50, 
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp, 
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                              child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                                : const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))
                            )
                          ),
                          const SizedBox(height: 15),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey)),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                              Expanded(child: Divider(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signUpWithGoogle,
                              icon: Image.network('https://developers.google.com/identity/images/g-logo.png', width: 24, height: 24),
                              label: const Text('Sign up with Google', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(onTap: () => Navigator.pop(context), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Already have an account? ", style: TextStyle(color: Colors.black54)), Text("Sign In", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
      ),
    );
  }
}