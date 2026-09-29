import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'notifications_screen.dart'; // Notification Screen එක Import කරන්න

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  String userName = "User";
  String userEmail = "No Email";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user!.reload();
      user = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        setState(() {
          userName = user?.displayName ?? "User"; 
          userEmail = user?.email ?? "No Email";
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // පොඩි Popup එකක් පෙන්වන්න (Language/Help වගේ ඒවට)
  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title feature is coming soon!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, size: 45, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded( // Text overflow නොවෙන්න Expanded දැම්මා
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                            child: Text("Passenger", style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Settings List with Navigation
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  children: [
                    // Notifications Page එකට යවන්න
                    _buildProfileItem(
                      Icons.notifications_outlined, 
                      "Notifications", 
                      Colors.orange.withOpacity(0.1),
                      Colors.orange,
                      onTap: () {
                        // Main Layout එකේ Tab එක මාරු කරනවා වෙනුවට කෙලින්ම Page එකට යවනවා නම්:
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                      }
                    ),
                    const Divider(height: 1, indent: 70, endIndent: 20),
                    
                    // Language (Placeholder)
                    _buildProfileItem(
                      Icons.language, 
                      "Language", 
                      Colors.blue.withOpacity(0.1),
                      Colors.blue,
                      onTap: () => _showComingSoon("Language Selection")
                    ),
                    const Divider(height: 1, indent: 70, endIndent: 20),
                    
                    // Help (Placeholder)
                    _buildProfileItem(
                      Icons.help_outline, 
                      "Help & Support", 
                      Colors.green.withOpacity(0.1),
                      Colors.green,
                      onTap: () => _showComingSoon("Support Center")
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Sign Out Button
              GestureDetector(
                onTap: () => _signOut(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 22),
                      SizedBox(width: 10),
                      Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, Color iconBgColor, Color iconColor, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap, // Click කළාම වැඩ කරන්න
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}