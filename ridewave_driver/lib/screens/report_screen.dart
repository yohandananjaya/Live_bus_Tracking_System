import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  final String busId; // බස් ID එක ඕනේ මැසේජ් යවන්නේ කවුද කියලා අඳුරගන්න
  const ReportScreen({super.key, required this.busId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _customMsgController = TextEditingController();
  final TextEditingController _adminReportController = TextEditingController();
  bool _isLoading = false;

  // Default Messages List (ලේසියෙන් යවන්න පුළුවන් ඒවා)
  final List<String> _quickAlerts = [
    "Bus Breakdown - Please Wait",
    "Heavy Traffic - 15 min Delay",
    "Tyre Puncture - 20 min Delay",
    "Trip Cancelled due to technical issue",
    "Bus is leaving in 5 minutes"
  ];

  // --- 1. මගීන්ට මැසේජ් යවන කොටස ---
  Future<void> _sendPassengerAlert(String message) async {
    setState(() => _isLoading = true);
    try {
      // 'notifications' කියන Collection එකට දානවා. Passenger App එක මේකෙන් කියවන්න ඕනේ.
      await FirebaseFirestore.instance.collection('notifications').add({
        'busId': widget.busId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'alert', // Passenger Alert එකක් බව හඟවන්න
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("Passengers Notified!")]),
            backgroundColor: Colors.green,
          )
        );
        _customMsgController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. Admin ට Report කරන කොටස ---
  Future<void> _sendAdminReport() async {
    if (_adminReportController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      // 'admin_reports' කියන Collection එකට දානවා. Admin Panel එකෙන් මේක බලන්න පුළුවන්.
      await FirebaseFirestore.instance.collection('admin_reports').add({
        'busId': widget.busId,
        'issue': _adminReportController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // තාම විසඳලා නෑ
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Report Sent"),
            content: const Text("Thank you. Admin support will check this issue."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        );
        _adminReportController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Report Center"),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.notifications_active), text: "Notify Passengers"),
              Tab(icon: Icon(Icons.support_agent), text: "Report to Admin"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: PASSENGER ALERTS ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quick Alerts (Tap to Send)", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAlerts.map((msg) => ActionChip(
                      avatar: const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                      label: Text(msg),
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: () => _sendPassengerAlert(msg),
                    )).toList(),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  Text("Custom Message", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customMsgController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Type custom alert for passengers...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _sendPassengerAlert(_customMsgController.text.trim()),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text("Send Alert to Passengers", style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  )
                ],
              ),
            ),

            // --- TAB 2: ADMIN REPORT ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[800]),
                        const SizedBox(width: 10),
                        const Expanded(child: Text("Use this form to report App bugs or System issues directly to the Admin Panel.")),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text("Describe Issue", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _adminReportController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: "E.g., Map is not loading, Login issue...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendAdminReport,
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text("Submit Report to Admin", style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}