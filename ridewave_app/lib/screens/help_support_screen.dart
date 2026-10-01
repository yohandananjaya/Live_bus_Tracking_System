import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Help & Support",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F1A35), // Dark blue PickMe style
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Topics Header
            Container(
              width: double.infinity,
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: const Text(
                "Select a topic",
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            
            _buildTopicTile(
              context,
              icon: Icons.login_outlined,
              title: "Account & Login Issues",
              categoryIndex: 0,
            ),
            _buildTopicTile(
              context,
              icon: Icons.directions_bus_outlined,
              title: "Live Tracking & Maps",
              categoryIndex: 1,
            ),
            _buildTopicTile(
              context,
              icon: Icons.notifications_active_outlined,
              title: "App Features & Notifications",
              categoryIndex: 2,
            ),
            _buildTopicTile(
              context,
              icon: Icons.security_outlined,
              title: "Safety & Emergency",
              categoryIndex: 3,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, {required IconData icon, required String title, required int categoryIndex}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Icon(icon, color: Colors.black87, size: 28),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HelpCategoryScreen(categoryData: helpData[categoryIndex])));
          },
        ),
        Divider(height: 1, color: Colors.grey[200], indent: 20, endIndent: 20),
      ],
    );
  }
}

// Category Screen (e.g., Account & Login Issues)
class HelpCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> categoryData;
  
  const HelpCategoryScreen({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> issues = categoryData['issues'];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                categoryData['title'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F1A35),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Please choose your issue",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            ...issues.map((issue) => _buildIssueTile(
              context, 
              issue['question']!, 
              articleTitle: issue['question']!,
              articleContent: issue['answer']!
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTile(BuildContext context, String issueTitle, {required String articleTitle, required String articleContent}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(issueTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HelpArticleScreen(title: articleTitle, content: articleContent)));
          },
        ),
        Divider(height: 1, color: Colors.grey[200], indent: 20, endIndent: 20),
      ],
    );
  }
}

// Article Screen
class HelpArticleScreen extends StatelessWidget {
  final String title;
  final String content;

  const HelpArticleScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F1A35),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 50),
            
            // Was this helpful section
            const Center(
              child: Text(
                "Was this helpful?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F1A35),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeedbackButton(Icons.thumb_up, Colors.green),
                const SizedBox(width: 20),
                _buildFeedbackButton(Icons.thumb_down, Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

// Data for Help & Support
final List<Map<String, dynamic>> helpData = [
  {
    "title": "Account & Login Issues",
    "issues": [
      {
        "question": "I don't receive the OTP code to login",
        "answer": "The OTP confirmation code is sent via SMS to the phone number you registered with.\n\nIf you haven't received it:\n1. Check your cellular network connection.\n2. Ensure the phone number entered is correct without the leading zero (e.g. +94 7X XXX XXXX).\n3. Wait a few seconds and tap on 'Resend Code'.\n\nIf the issue persists, you can try logging in via your Google Account."
      },
      {
        "question": "How do I sign in with my Google Account?",
        "answer": "To sign in using Google, tap the 'Sign in with Google' button on the Login screen. You will be prompted to choose a Google account linked to your device. If it's your first time, you will also be asked to verify your phone number to complete the registration."
      },
      {
        "question": "I changed my phone number, how do I recover my account?",
        "answer": "Currently, accounts are strictly linked to your verified phone number for security purposes. If you have completely lost access to your old number, you may need to create a new account using your new number. If you previously linked a Google account, you can still sign in using Google."
      }
    ]
  },
  {
    "title": "Live Tracking & Maps",
    "issues": [
      {
        "question": "Why is the bus location not updating?",
        "answer": "Bus locations are updated in real-time based on the GPS data sent from the driver's app. If a bus location is not updating:\n\n1. The bus might be passing through an area with poor network coverage.\n2. The driver might have temporarily paused the trip or gone offline.\n3. Your device might be experiencing internet connectivity issues. Try refreshing the app or checking your connection."
      },
      {
        "question": "How to search for a specific bus route?",
        "answer": "You can find specific bus routes by going to the 'Search' or 'Routes' tab. Enter your 'From' and 'To' destinations in the search bar. The app will filter and display all active buses currently traveling on routes that match your criteria."
      },
      {
        "question": "Is the live tracking accurate?",
        "answer": "Yes, our live tracking system uses GPS coordinates updated every few seconds. However, minor delays of 5-10 seconds might occur depending on network latency. The estimated arrival times are calculated considering current traffic conditions and the bus's speed."
      }
    ]
  },
  {
    "title": "App Features & Notifications",
    "issues": [
      {
        "question": "How do I get notifications for bus arrivals?",
        "answer": "To get notified when a bus is arriving at your stop:\n\n1. Select a bus on the live map.\n2. Tap the 'Remind Me' or 'Set Alert' button.\n3. Choose how many minutes before arrival you want to be notified (e.g. 5 mins, 10 mins).\n\nMake sure you have granted Notification permissions to the RideWave app in your phone's settings."
      },
      {
        "question": "Can I save my favorite routes?",
        "answer": "Yes! When you view a route, you can tap the 'Heart' icon to save it to your Favorites. You can easily access your favorite routes later from the 'Favorites' section in the bottom navigation bar without having to search for them again."
      }
    ]
  },
  {
    "title": "Safety & Emergency",
    "issues": [
      {
        "question": "How to use the Emergency SOS feature?",
        "answer": "If you feel unsafe or have a medical emergency during your journey:\n\n1. Tap the red 'Emergency' icon located in the bottom navigation bar.\n2. You will be redirected to the Emergency screen.\n3. From there, you can directly call the Police (119), Ambulance (1990), or contact RideWave Support.\n\nYour current live location can also be shared with authorities if necessary."
      }
    ]
  }
];

