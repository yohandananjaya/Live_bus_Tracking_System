import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSeatView extends StatelessWidget {
  final String busId;
  const DriverSeatView({super.key, required this.busId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seat Layout")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> bookedSeats = data['bookedSeats'] ?? [];

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: Colors.red), Text(" Booked  "),
                    Icon(Icons.circle, color: Colors.green), Text(" Available"),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    itemCount: 32,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 20, childAspectRatio: 1.2),
                    itemBuilder: (context, index) {
                      if (index % 4 == 2 && index < 28) return const SizedBox(); 
                      String seatNo = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                      bool isBooked = bookedSeats.contains(seatNo);

                      return Container(
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.red : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isBooked ? Colors.redAccent : Colors.green),
                        ),
                        child: Center(child: Text(seatNo, style: TextStyle(color: isBooked ? Colors.white : Colors.green[800], fontWeight: FontWeight.bold))),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}