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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Report Center", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // --- 1. Background Image Header ---
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.35,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/bus_red.jpg'), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // TabBar placed at the bottom of the image area
                      const TabBar(
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(icon: Icon(Icons.notifications_active), text: "Notify Passengers"),
                          Tab(icon: Icon(Icons.support_agent), text: "Report to Admin"),
                        ],
                      ),
                      const SizedBox(height: 30), // extra padding to prevent clipping by white container
                    ],
                  ),
                ),
              ),
            ),

            // --- 2. Sliding White Container for Content ---
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // --- TAB 1: PASSENGER ALERTS ---
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Quick Alerts", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                                const SizedBox(height: 5),
                                Text("Tap to instantly notify passengers", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 15),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _quickAlerts.map((msg) => ActionChip(
                                    avatar: const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                                    label: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    backgroundColor: Colors.grey.shade50,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                    onPressed: () => _sendPassengerAlert(msg),
                                  )).toList(),
                                ),
                                const SizedBox(height: 30),
                                Text("Custom Message", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _customMsgController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: "Type custom alert for passengers...",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.all(15)
                                  ),
                                ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : () => _sendPassengerAlert(_customMsgController.text.trim()),
                                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                                    label: const Text("SEND ALERT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 5,
                                      shadowColor: Colors.redAccent.withOpacity(0.5)
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),

                          // --- TAB 2: ADMIN REPORT ---
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue[800], size: 28),
                                      const SizedBox(width: 15),
                                      const Expanded(child: Text("Use this form to report App bugs or System issues directly to the Admin Panel.", style: TextStyle(height: 1.3))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Text("Issue Description", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _adminReportController,
                                  maxLines: 8,
                                  decoration: InputDecoration(
                                    hintText: "Please describe the issue in detail...",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.all(15)
                                  ),
                                ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _sendAdminReport,
                                    icon: const Icon(Icons.upload_file, color: Colors.white),
                                    label: const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[800],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 5,
                                      shadowColor: Colors.blue.withOpacity(0.5)
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
