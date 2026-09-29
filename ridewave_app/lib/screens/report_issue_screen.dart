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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Report Issue", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Image (Top Header)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/report_bg.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Text
                const Padding(
                  padding: EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Need Help?", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("Tell us what went wrong, and we'll fix it.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
                
                // Form Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 30, left: 25, right: 25, bottom: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Issue Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                          const SizedBox(height: 15),
                          
                          // Issue Type Grid
                          GridView.count(
                            padding: EdgeInsets.zero,
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.5, // Sleek, wide button look
                            children: [
                              _buildIssueChip(Icons.access_time, "Bus Delay"),
                              _buildIssueChip(Icons.location_off, "Wrong Location"),
                              _buildIssueChip(Icons.warning_amber, "Safety Concern"),
                              _buildIssueChip(Icons.help_outline, "Other Issue"),
                            ],
                          ),

                          const SizedBox(height: 30),

                          const Text("Bus Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                          const SizedBox(height: 10),
                          _buildTextField("Bus Number (e.g., KY-1234)", Icons.directions_bus_outlined, maxLines: 1),

                          const SizedBox(height: 25),

                          const Text("Describe the Issue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                          const SizedBox(height: 10),
                          _buildTextField("Please provide details about the issue...", Icons.description_outlined, maxLines: 4),


                          const SizedBox(height: 35),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Submitted Successfully!")));
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                              label: const Text("Submit Report", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 5,
                                shadowColor: Colors.blue.withOpacity(0.4),
                              ),
                            ),
                          ),
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

  Widget _buildTextField(String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey[500]) : null,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.blue[700]!, width: 2)),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildIssueChip(IconData icon, String label) {
    bool isSelected = selectedIssue == label;
    return GestureDetector(
      onTap: () => setState(() => selectedIssue = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}