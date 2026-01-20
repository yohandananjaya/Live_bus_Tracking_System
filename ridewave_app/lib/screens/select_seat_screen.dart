import 'package:flutter/material.dart';

class SelectSeatScreen extends StatefulWidget {
  // Home Screen එකෙන් එවන ඩේටා ලබාගන්න variables
  final String busId;
  final String busName;
  final String route;
  final String price;
  final List<String> bookedSeats;

  const SelectSeatScreen({
    super.key, 
    required this.busId,
    required this.busName,
    required this.route,
    required this.price,
    required this.bookedSeats,
  });

  @override
  State<SelectSeatScreen> createState() => _SelectSeatScreenState();
}

class _SelectSeatScreenState extends State<SelectSeatScreen> {
  // මම තෝරාගත් සීට් ලිස්ට් එක
  List<String> selectedSeats = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Seats", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Bus Info Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.busName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.route, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Text("Rs. ${widget.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue, "Selected"),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.grey, "Booked"),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.white, "Available", hasBorder: true),
            ],
          ),

          const SizedBox(height: 20),

          // Driver Area
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5)),
            child: const Center(child: Text("Driver", style: TextStyle(color: Colors.grey))),
          ),
          
          const SizedBox(height: 20),

          // Seats Layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: GridView.builder(
                itemCount: 32, // සීට් ගාණ
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  // Aisle
                  if (index % 4 == 2 && index < 28) return const SizedBox(); 

                  // Seat No logic (A1, A2...)
                  String seatNo = "${String.fromCharCode(65 + (index / 4).floor())}${(index % 4) + 1}";
                  
                  // Check status
                  bool isBooked = widget.bookedSeats.contains(seatNo);
                  bool isSelected = selectedSeats.contains(seatNo);

                  return GestureDetector(
                    onTap: () {
                      if (isBooked) return;
                      setState(() {
                        if (isSelected) {
                          selectedSeats.remove(seatNo);
                        } else {
                          selectedSeats.add(seatNo);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBooked ? Colors.grey[300] : (isSelected ? Colors.blue : Colors.white),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isBooked ? Colors.transparent : Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(seatNo, style: TextStyle(
                          color: isSelected ? Colors.white : (isBooked ? Colors.grey : Colors.black)
                        )),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Bar (Confirm)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Selected: ${selectedSeats.join(', ')}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    // Price calculation logic can be added here
                    Text("Total: Rs. ${selectedSeats.length * (double.tryParse(widget.price) ?? 0)}", 
                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedSeats.isEmpty ? null : () {
                      // Booking Logic goes here (Update Firebase)
                      print("Booking Confirmed: $selectedSeats for Bus ${widget.busId}");
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Request Sent!")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: hasBorder ? Border.all(color: Colors.grey[300]!) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}