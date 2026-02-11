import 'package:flutter/material.dart';

class DriverReportScreen extends StatelessWidget {
  const DriverReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Issue")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Describe your issue, we will contact you shortly."),
            const SizedBox(height: 20),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Type your message here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Sent to Admin!")));
                  Navigator.pop(context);
                }, 
                child: const Text("Submit Report")
              ),
            )
          ],
        ),
      ),
    );
  }
}