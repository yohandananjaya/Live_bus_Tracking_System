import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  // තෝරාගත් ප්‍රශ්න වර්ගය (Issue Type)
  String selectedIssue = "Bus Delay";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Report Issue", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Issue Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
            // Issue Type Selection Grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildIssueChip(Icons.access_time, "Bus Delay"),
                _buildIssueChip(Icons.location_off, "Wrong Location"),
                _buildIssueChip(Icons.warning_amber, "Safety Concern"),
                _buildIssueChip(Icons.help_outline, "Other Issue"),
              ],
            ),

            const SizedBox(height: 25),

            // Bus Info Input
            const Text("Bus Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: "Bus Number (e.g., KY-1234)",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),

            const SizedBox(height: 25),

            // Description Input
            const Text("Describe the Issue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Please provide details about the issue...",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 25),

            // Add Photo (Optional)
            const Text("Add Photo (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid), // Dashed border අමාරු නිසා solid දැම්මා
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.grey[400]),
                  const SizedBox(height: 5),
                  Text("Tap to upload a photo", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Submit Logic goes here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Report Submitted Successfully!")),
                  );
                  Navigator.pop(context); // Go back home
                },
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                label: const Text("Submit Report", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueChip(IconData icon, String label) {
    bool isSelected = selectedIssue == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIssue = label;
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 50) / 2, // හරියටම දෙකට බෙදන්න
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.black54),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}