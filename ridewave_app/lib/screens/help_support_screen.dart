import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/home_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: const Text(
                  "Welcome to RideWave",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "About RideWave System",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "RideWave is an advanced live bus tracking and management system. We aim to provide real-time updates and seamless travel experiences for passengers, ensuring you never miss a bus again.",
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 25),

                  _buildFeatureSection(
                    title: "Live Tracking & Maps",
                    description: "Monitor your bus locations in real-time. Our smart mapping system gives you exact locations, moving live on the map.",
                    imageAsset: "assets/images/logo.png",
                    icon: Icons.map_outlined,
                  ),
                  
                  const SizedBox(height: 25),

                  _buildFeatureSection(
                    title: "Smart Notifications",
                    description: "Get alerts when a bus is arriving, delayed, or if there are emergencies. Stay informed at all times.",
                    imageAsset: "assets/home_bg.jpg",
                    icon: Icons.notifications_active_outlined,
                    isReversed: true,
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    "Need More Help?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),

                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: "Email Us",
                    subtitle: "support@ridewave.lk",
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: "Call Hotline",
                    subtitle: "+94 112 345 678",
                    color: Colors.green,
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

  Widget _buildFeatureSection({
    required String title,
    required String description,
    required String imageAsset,
    required IconData icon,
    bool isReversed = false,
  }) {
    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        imageAsset,
        height: 120,
        width: 120,
        fit: BoxFit.cover,
      ),
    );

    final textWidget = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isReversed 
            ? [textWidget, const SizedBox(width: 15), imageWidget]
            : [imageWidget, const SizedBox(width: 15), textWidget],
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
