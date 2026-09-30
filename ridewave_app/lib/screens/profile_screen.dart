import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';

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
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _showComingSoon("Edit Profile"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section: Cover Image & Profile Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Cover Image
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/home_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Profile Avatar
                Positioned(
                  bottom: -50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.blue[600],
                      child: Text(
                        userEmail != "No Email" && userEmail.isNotEmpty 
                            ? userEmail[0].toUpperCase() 
                            : "?",
                        style: const TextStyle(
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 60),

            // User Info Section
            Text(
              userName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 5),
            Text(
              userEmail,
              style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Text(
                "Passenger",
                style: TextStyle(color: Colors.blue[700], fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),

            const SizedBox(height: 35),

            // Settings Options Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, spreadRadius: 1),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          Icons.notifications_outlined, 
                          "Notifications", 
                          Colors.orange.withOpacity(0.1),
                          Colors.orange,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                          }
                        ),
                        _buildProfileItem(
                          Icons.help_outline, 
                          "Help & Support", 
                          Colors.green.withOpacity(0.1),
                          Colors.green,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                          }
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
                        color: Colors.white,
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
                        ],
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
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, Color iconBgColor, Color iconColor, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}