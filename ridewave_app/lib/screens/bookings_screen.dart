import 'package:flutter/material.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Tabs 2ක් තියෙනවා (Upcoming, Completed)
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("My Bookings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Upcoming Bookings List
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  _buildBookingCard(
                    "KY-1234", "Express Liner", "Kandy", "Colombo", "Today, 08:30 AM", "A1, A2", "Rs. 1500", true
                  ),
                ],
              ),
            ),
            
            // 2. Completed Bookings List
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  _buildBookingCard(
                    "CM-5678", "City Transit", "Colombo", "Galle", "Yesterday", "B4", "Rs. 650", false
                  ),
                  _buildBookingCard(
                    "KD-9900", "Hill Country", "Badulla", "Colombo", "12 Nov", "C1, C2", "Rs. 2000", false
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(String busNo, String name, String from, String to, String date, String seats, String price, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)),
                child: Text(busNo, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isUpcoming ? Colors.green[50] : Colors.grey[100], 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(
                  isUpcoming ? "Scheduled" : "Completed", 
                  style: TextStyle(color: isUpcoming ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(from, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(to, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(name, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Seats", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(seats, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Total Price", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(price, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Cancel Booking", style: TextStyle(color: Colors.red)),
              ),
            )
          ]
        ],
      ),
    );
  }
}