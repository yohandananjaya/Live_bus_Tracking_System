import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Emergency", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Alert Box
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Emergency Help", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 5),
                  Text(
                    "If you are in an emergency situation, tap any number below to call for immediate assistance.",
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),

            // Emergency Contacts List
            _buildContactCard(Icons.security, "RideWave Support", "1800-123-4567"),
            const SizedBox(height: 15),
            _buildContactCard(Icons.local_police, "Police Emergency", "119"),
            const SizedBox(height: 15),
            _buildContactCard(Icons.medical_services, "Ambulance", "110"),

            const SizedBox(height: 30),

            // SOS Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // SOS Call Logic
                },
                icon: const Icon(Icons.phone_in_talk, color: Colors.white),
                label: const Text("Emergency SOS Call", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: Colors.red.withOpacity(0.5),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Safety Tips
            const Text("Safety Tips", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            _buildSafetyTip("Share your live location with a trusted contact"),
            _buildSafetyTip("Stay aware of your surroundings at all times"),
            _buildSafetyTip("Keep your valuables secure and out of sight"),
            _buildSafetyTip("Report any suspicious activity to authorities"),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(number, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: const Icon(Icons.call, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    );
  }
}