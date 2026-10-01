import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'notifications_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  String userName = "Loading...";
  String userEmail = "Loading...";
  String userInitials = "";

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
          userName = user?.displayName ?? "Passenger User"; 
          userEmail = user?.email ?? "No Email Linked";
          
          if (userName.isNotEmpty && userName != "Passenger User") {
            List<String> names = userName.split(" ");
            if (names.length > 1) {
              userInitials = "${names[0][0]}${names[1][0]}".toUpperCase();
            } else {
              userInitials = userName[0].toUpperCase();
            }
          } else if (userEmail.isNotEmpty && userEmail != "No Email Linked") {
             userInitials = userEmail[0].toUpperCase();
          } else {
             userInitials = "P";
          }
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title is under development!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blueGrey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Soft modern background
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Custom Curved Header
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                _buildHeaderBackground(),
                
                // Top App Bar Icons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "My Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showComingSoon("Edit Profile"),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Avatar & Basic Info
                Positioned(
                  top: 110,
                  child: Column(
                    children: [
                      // Glowing Avatar
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.blue[800],
                            child: Text(
                              userInitials,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Premium Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              "Verified Passenger",
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Stats Card (Overlapping the header)
                Positioned(
                  top: 340,
                  left: 25,
                  right: 25,
                  child: _buildFloatingStatsCard(),
                ),
              ],
            ),
            
            // Spacer for floating card
            const SizedBox(height: 80),

            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "General Settings",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Options List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildOptionTile(
                          icon: Icons.notifications_active_rounded,
                          title: "Notifications",
                          subtitle: "Manage alerts & sounds",
                          iconBgColor: Colors.orange[50]!,
                          iconColor: Colors.orange[800]!,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                          },
                        ),
                        _buildDivider(),
                        _buildOptionTile(
                          icon: Icons.payment_rounded,
                          title: "Payment Methods",
                          subtitle: "Cards & digital wallets",
                          iconBgColor: Colors.indigo[50]!,
                          iconColor: Colors.indigo[800]!,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
                          },
                        ),
                        _buildDivider(),
                        _buildOptionTile(
                          icon: Icons.help_center_rounded,
                          title: "Help & Support",
                          subtitle: "FAQ & contact us",
                          iconBgColor: Colors.blue[50]!,
                          iconColor: Colors.blue[800]!,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                          },
                        ),
                        _buildDivider(),
                        _buildOptionTile(
                          icon: Icons.info_outline_rounded,
                          title: "About RideWave",
                          subtitle: "App info & version",
                          iconBgColor: Colors.teal[50]!,
                          iconColor: Colors.teal[800]!,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign Out Button
                  Center(
                    child: GestureDetector(
                      onTap: () => _signOut(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red[700], size: 22),
                            const SizedBox(width: 10),
                            Text(
                              "Sign Out",
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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

  // Beautiful Dark Gradient Header
  Widget _buildHeaderBackground() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Add some subtle background patterns/circles
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Stats Card
  Widget _buildFloatingStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.favorite_rounded, "3", "Favorites", Colors.redAccent),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _buildStatItem(Icons.confirmation_number_rounded, "1", "Tickets", Colors.orange),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _buildStatItem(Icons.notifications_active_rounded, "2", "Alerts", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Divider(height: 1, color: Colors.grey[100]),
    );
  }
}