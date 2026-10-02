import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch $launchUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Emergency Options", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header with Red Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 40, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.redAccent, blurRadius: 20, offset: Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Are you in an emergency?",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Tap below to get immediate assistance.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 15),

                  // Emergency Contacts List with Call Action
                  _buildContactCard(Icons.local_police, "Police Emergency", "119", Colors.blue),
                  const SizedBox(height: 15),
                  _buildContactCard(Icons.medical_services, "Ambulance", "1990", Colors.green),
                  const SizedBox(height: 15),
                  _buildContactCard(Icons.security, "RideWave Hotline", "+94472345675", Colors.orange),

                  const SizedBox(height: 35),

                  // Big SOS Button
                  Center(
                    child: InkWell(
                      onTap: () => _makePhoneCall("119"),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 30, spreadRadius: 10)
                          ],
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                            center: Alignment.topLeft,
                            radius: 1.0,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos_rounded, color: Colors.white, size: 60),
                            Text("SOS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Safety Tips
                  const Text("Safety Tips", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 15),
                  _buildSafetyTip(Icons.location_on, "Share your live location with a trusted contact"),
                  _buildSafetyTip(Icons.remove_red_eye, "Stay aware of your surroundings at all times"),
                  _buildSafetyTip(Icons.report, "Report suspicious activity to the conductor or driver"),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String number, Color accentColor) {
    return InkWell(
      onTap: () => _makePhoneCall(number),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(number, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.call, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
