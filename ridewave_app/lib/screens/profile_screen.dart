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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded( // Text overflow නොවෙන්න Expanded දැම්මා
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(10)),
                            child: const Text("Passenger", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
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
                      onTap: () {
                        // Main Layout එකේ Tab එක මාරු කරනවා වෙනුවට කෙලින්ම Page එකට යවනවා නම්:
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                      }
                    ),
                    const Divider(height: 1),
                    
                    // Language (Placeholder)
                    _buildProfileItem(Icons.language, "Language", onTap: () => _showComingSoon("Language Selection")),
                    const Divider(height: 1),
                    
                    // Help (Placeholder)
                    _buildProfileItem(Icons.help_outline, "Help & Support", onTap: () => _showComingSoon("Support Center")),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Sign Out Button
              GestureDetector(
                onTap: () => _signOut(context),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 15),
                      Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  Widget _buildProfileItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap, // Click කළාම වැඩ කරන්න
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}