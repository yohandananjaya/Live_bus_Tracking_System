import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatView extends StatelessWidget {
  final String busId;
  const SeatView({super.key, required this.busId});

  // Manual Reset Function
  void _resetSeats(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Seats?"),
        content: const Text("This will make all seats 'Available'. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('buses').doc(busId).update({'bookedSeats': []});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seats Cleared!")));
            }, 
            child: const Text("Clear All", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Seat Layout"), 
        backgroundColor: Colors.blue[800], 
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      // 🔥 අලුත් Button එක: Clear Seats Manually
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _resetSeats(context),
        label: const Text("Reset Seats"),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.white, "Available", isBorder: true),
                _buildLegendItem(Colors.redAccent, "Booked"),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                List booked = snapshot.data!['bookedSeats'] ?? [];
                
                return GridView.builder(
                  padding: const EdgeInsets.all(30),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, 
                    crossAxisSpacing: 15, 
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 32,
                  itemBuilder: (context, index) {
                    if (index % 4 == 2 && index < 28) return const SizedBox();
                    
                    String seatName = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                    bool isBooked = booked.contains(seatName);

                    return Container(
                      decoration: BoxDecoration(
                        color: isBooked ? Colors.redAccent : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15), bottom: Radius.circular(5)),
                        border: isBooked ? null : Border.all(color: Colors.blue[200]!, width: 2),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Center(
                        child: Text(
                          seatName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBooked ? Colors.white : Colors.blue[800],
                            fontSize: 16,
                          ),
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

  Widget _buildLegendItem(Color color, String label, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isBorder ? Border.all(color: Colors.blue[200]!, width: 2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}