import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatelessWidget {
  final String busId;
  const TripHistoryScreen({super.key, required this.busId});

  // --- Safe Parsing Utilities ---
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) return DateTime.tryParse(dateValue);
    return null;
  }

  static String _formatPayoutDate(dynamic dateValue) {
    DateTime? dt = _parseDate(dateValue);
    if (dt != null) {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    }
    return "Recent";
  }

  static String _formatTravelDate(String dateStr) {
    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      return DateFormat('EEE, MMM dd, yyyy').format(dt);
    }
    return dateStr;
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF0F2027)),
            SizedBox(width: 8),
            Text("Payout Information"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "• Trip Revenue:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Calculated from confirmed passenger bookings. Driver receives 95% of total ticket sales after a 5% platform commission.",
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              "• Admin Payouts:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "When Admin transfers your earnings to your bank account, the settlement record appears in the Admin Payouts tab.",
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
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
          title: const Text(
            "Financials",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showInfoDialog(context),
              tooltip: "Payout Info",
            )
          ],
        ),
        body: Stack(
          children: [
            // --- 1. Top Background Header with Tabs ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.32,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TabBar(
                      indicatorColor: Colors.greenAccent,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: "Trip Revenue", icon: Icon(Icons.account_balance_wallet_rounded)),
                        Tab(text: "Admin Payouts", icon: Icon(Icons.account_balance_rounded)),
                      ],
                    ),
                    SizedBox(height: 25),
                  ],
                ),
              ),
            ),

            // --- 2. Sliding White Container for Tab Contents ---
            Positioned(
              top: MediaQuery.of(context).size.height * 0.28,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTripRevenueTab(),
                          _buildAdminPayoutsTab(),
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

  // =========================================================================
  // TAB 1: Trip Revenue (Pending Payouts from Bookings)
  // =========================================================================
  Widget _buildTripRevenueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('busId', isEqualTo: busId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  Text("Error loading bookings: ${snapshot.error}", textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: "No Bookings Found",
            message: "Passenger ticket bookings for this bus will appear here.",
          );
        }

        // Group pending (unsettled) bookings by travelDate
        // Business logic: include both 'confirmed' and 'completed' bookings
        // (excluding refunded, cancelled, or already settled)
        Map<String, _DateRevenueGroup> pendingGroups = {};
        double totalPendingNet = 0.0;
        int totalPendingBookings = 0;

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          bool settled = data['payoutSettled'] == true;
          String status = (data['status'] ?? '').toString().toLowerCase();

          // Exclude already settled or refunded / cancelled bookings
          if (settled) continue;
          if (status == 'refunded' || status == 'cancelled' || status == 'refund_requested') continue;

          // Accept confirmed or completed bookings
          if (status == 'confirmed' || status == 'completed') {
            String date = (data['travelDate'] != null && data['travelDate'].toString().isNotEmpty)
                ? data['travelDate'].toString()
                : 'Unknown Date';

            double grossPrice = _parsePrice(data['totalPrice']);
            double netEarnings = grossPrice * 0.95; // 5% platform commission
            double commission = grossPrice * 0.05;

            List seats = data['seats'] is List ? data['seats'] : [];

            if (!pendingGroups.containsKey(date)) {
              pendingGroups[date] = _DateRevenueGroup(travelDate: date);
            }

            var group = pendingGroups[date]!;
            group.grossTotal += grossPrice;
            group.netTotal += netEarnings;
            group.commissionTotal += commission;
            group.bookingCount += 1;
            group.seatCount += seats.length;

            totalPendingNet += netEarnings;
            totalPendingBookings += 1;
          }
        }

        if (pendingGroups.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: "All Caught Up!",
            message: "No pending revenue to settle. All completed trips have been settled by Admin.",
          );
        }

        // Sort dates descending
        List<String> sortedDates = pendingGroups.keys.toList();
        sortedDates.sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00B09B).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Pending Payout",
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs. ${totalPendingNet.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$totalPendingBookings booking(s) • 95% net after 5% fee",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                "Pending Revenue By Date",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            ...sortedDates.map((dateStr) {
              final group = pendingGroups[dateStr]!;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                _formatTravelDate(group.travelDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              "PENDING",
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Net Driver Earnings",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Rs. ${group.netTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${group.bookingCount} Booking(s) • ${group.seatCount} Seat(s)",
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Gross: Rs. ${group.grossTotal.toStringAsFixed(0)} (-5%)",
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TAB 2: Admin Payouts (Settled Transfers Received from Admin)
  // =========================================================================
  Widget _buildAdminPayoutsTab() {
    // IMPORTANT: No .orderBy in the Firestore query to prevent composite index errors!
    // We sort the snapshots in Dart in-memory instead.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payouts')
          .where('busId', isEqualTo: busId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  Text("Error loading payouts: ${snapshot.error}", textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance_rounded,
            title: "No Payouts Received Yet",
            message: "When Admin transfers your trip earnings, the transfer records will appear here.",
          );
        }

        // Copy and sort in-memory by date descending
        List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          DateTime aDate = _parseDate(aData['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          DateTime bDate = _parseDate(bData['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        // Calculate total settled payouts
        double totalSettled = 0.0;
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          totalSettled += _parsePrice(data['amountTransferred']);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          children: [
            // Payout Total Card
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E3C72).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Payouts Received",
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs. ${totalSettled.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${docs.length} settlement transfer(s)",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                "Transfer History",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            ...docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              double amount = _parsePrice(data['amountTransferred']);
              String status = (data['status'] ?? 'settled').toString();
              String refNo = data['referenceNo'] ?? data['payoutRef'] ?? "PAY-${doc.id.substring(0, 7).toUpperCase()}";
              String transferredDate = _formatPayoutDate(data['date']);
              String? travelDate = data['travelDate']?.toString();
              String type = data['type'] == 'refund_fee' ? "Driver Refund Fee" : "Commission Settlement";

              bool isSettled = status.toLowerCase() == 'settled';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.account_balance_rounded, size: 20, color: Colors.blue[800]),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    refNo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    type,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSettled ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSettled ? Colors.green.shade200 : Colors.orange.shade200),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: isSettled ? Colors.green.shade800 : Colors.orange.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (travelDate != null && travelDate.isNotEmpty) ...[
                                Text(
                                  "Trip Date: ${_formatTravelDate(travelDate)}",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                "Transferred: $transferredDate",
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            "Rs. ${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 55, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRevenueGroup {
  final String travelDate;
  double grossTotal = 0.0;
  double netTotal = 0.0;
  double commissionTotal = 0.0;
  int bookingCount = 0;
  int seatCount = 0;

  _DateRevenueGroup({required this.travelDate});
}
