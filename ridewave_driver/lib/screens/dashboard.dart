import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import 'login_screen.dart';
import 'seat_view.dart';
import 'bookings_screen.dart';
import 'report_screen.dart';
import 'driver_map_screen.dart';
import 'trip_history_screen.dart';
import 'timetable_screen.dart';

class Dashboard extends StatefulWidget {
  final String busId;
  const Dashboard({super.key, required this.busId});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;

  // --- අද දවසට අදාළ ට්‍රිප් එක තෝරාගෙන පටන් ගැනීම ---
  Future<void> _showTodaySchedulesAndStart() async {
    String todayStr = DateFormat('EEEE').format(DateTime.now()); // e.g. Monday

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Trip for Today ($todayStr)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schedules')
                      .where('busId', isEqualTo: widget.busId)
                      .where('dayOfWeek', isEqualTo: todayStr)
                      .orderBy('departureTime')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No trips scheduled for today.\nPlease add them in the Time Table.", 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)
                        )
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            tileColor: Colors.blue[50],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(Icons.directions_bus, color: Colors.blue[800]),
                            title: Text("${data['routeFrom']} to ${data['routeTo']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Time: ${data['departureTime']} | Ticket: Rs.${data['price']}"),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showGpsSelectionDialog(data['routeFrom'], data['routeTo'], data['price']);
                              },
                              child: const Text("Start", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showGpsSelectionDialog(String from, String to, dynamic price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select GPS Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text("Phone Location"),
              onTap: () {
                Navigator.pop(ctx);
                _startScheduledTrip(from, to, price, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text("Hardware Tracker"),
              onTap: () {
                Navigator.pop(ctx);
                _startScheduledTrip(from, to, price, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- තෝරපු ට්‍රිප් එකෙන් ගමන ආරම්භ කිරීම ---
  Future<void> _startScheduledTrip(String from, String to, dynamic price, bool usePhoneGPS) async {
    setState(() => _isLoading = true);
    
    try {
      bool started = await _locationService.startTrip(widget.busId, usePhoneGPS);
      
      if (started) {
        await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({
          'status': 'Live',
          'routeFrom': from,
          'routeTo': to,
          'price': price.toString(),
          'gpsSource': usePhoneGPS ? 'Phone' : 'Hardware',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Started!"), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GPS Permission Denied!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ට්‍රිප් එක පටන් ගැනීම සහ අවසන් කිරීම ---
  void _toggleTrip(bool isLive, double currentRevenue) async {
    if (isLive) {
      // END JOURNEY
      setState(() => _isLoading = true);
      await _locationService.stopTrip();
      
      if (currentRevenue > 0) {
        await FirebaseFirestore.instance.collection('buses').doc(widget.busId).collection('trip_history').add({
          'revenue': currentRevenue,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({
        'status': 'Idle',
        'totalRevenue': 0, 
      });
      
      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Journey Ended"),
            content: const Text("Clear seats and mark all current bookings as Completed?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  Navigator.pop(ctx); 
                  await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({'bookedSeats': []});

                  var batch = FirebaseFirestore.instance.batch();
                  var snapshots = await FirebaseFirestore.instance
                      .collection('bookings')
                      .where('busId', isEqualTo: widget.busId)
                      .where('status', isEqualTo: 'confirmed') 
                      .get();

                  for (var doc in snapshots.docs) {
                    batch.update(doc.reference, {'status': 'completed'});
                  }
                  await batch.commit(); 

                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Journey Finished!")));
                }, 
                child: const Text("Yes, Finish All", style: TextStyle(color: Colors.white))
              ),
            ],
          ),
        );
      }
    } else {
      // START JOURNEY
      _showTodaySchedulesAndStart(); 
    }
  }

  Future<void> _handleLogout(bool isLive) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Exit app? Active trips will stop."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      if (isLive) {
        await _locationService.stopTrip();
        await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({'status': 'Idle'});
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Soft background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2027), // Dark premium color
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "RideWave Driver", 
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 0.5, color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').doc(widget.busId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var data = snapshot.data!.data() as Map<String, dynamic>;
          bool isLive = data['status'] == 'Live';
          String price = data['price']?.toString() ?? "0";
          double revenue = (data['totalRevenue'] ?? 0).toDouble();
          String busNo = data['busNo'] ?? "Unknown Bus";
          
          String routeFrom = data['routeFrom'] != null && data['routeFrom'].toString().isNotEmpty ? data['routeFrom'] : "Not Set";
          String routeTo = data['routeTo'] != null && data['routeTo'].toString().isNotEmpty ? data['routeTo'] : "Not Set";

          return Column(
            children: [
              // --- 1. Top Premium Header ---
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 35),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            busNo, 
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.greenAccent[400] : Colors.redAccent, 
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isLive ? Colors.greenAccent[400]! : Colors.redAccent).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 10, color: Colors.white), 
                              const SizedBox(width: 8), 
                              Text(
                                isLive ? "ONLINE" : "OFFLINE", 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, letterSpacing: 1),
                              )
                            ]
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 20, color: Colors.blue[200]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "$routeFrom  ➔  $routeTo", 
                            style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600), 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _statCard("Total Revenue", "Rs. $revenue", Icons.account_balance_wallet_rounded, Colors.greenAccent[100]!)),
                        const SizedBox(width: 15),
                        Expanded(child: _statCard("Ticket Price", "Rs. $price", Icons.confirmation_number_rounded, Colors.orangeAccent[100]!)),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 2. Action Grid ---
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      padding: const EdgeInsets.only(top: 0, bottom: 20),
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.9, 
                      children: [
                        _actionCard("Live Map", Icons.map_rounded, Colors.blue[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => DriverMapScreen(busId: widget.busId)))),
                        _actionCard("Bookings", Icons.confirmation_number_rounded, Colors.indigo[600]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingsScreen(busId: widget.busId)))),
                        _actionCard("Seats", Icons.grid_view_rounded, Colors.lightBlue[600]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeatView(busId: widget.busId)))),
                        _actionCard("Report", Icons.warning_rounded, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportScreen(busId: widget.busId)))),
                        _actionCard("History", Icons.history_rounded, Colors.teal[600]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => TripHistoryScreen(busId: widget.busId)))),
                        _actionCard("Schedule", Icons.schedule_rounded, Colors.purple[500]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => TimeTableScreen(busId: widget.busId)))),
                      ],
                    ),
                  ),
                ),
              ),
              
              // --- 3. Bottom Start/End Journey Button ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5))]
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _toggleTrip(isLive, revenue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? Colors.redAccent : const Color(0xFF00C853),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: (isLive ? Colors.redAccent : const Color(0xFF00C853)).withOpacity(0.5),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isLive ? Icons.stop_circle_outlined : Icons.play_circle_filled_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              isLive ? "END JOURNEY" : "START JOURNEY", 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ), 
          const SizedBox(height: 8), 
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
        ]
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1), 
              blurRadius: 15, 
              offset: const Offset(0, 6),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                shape: BoxShape.circle,
              ), 
              child: Icon(icon, size: 28, color: color)
            ), 
            const SizedBox(height: 10), 
            Text(
              title, 
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blueGrey[800]),
              textAlign: TextAlign.center,
            )
          ]
        ),
      ),
    );
  }
}
