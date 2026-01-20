import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // User චෙක් කරන්න මේක ඕන
import 'screens/login_screen.dart';
import 'screens/main_layout.dart'; // Home එකට යන්න මේක ඕන

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RideWaveApp());
}

class RideWaveApp extends StatelessWidget {
  const RideWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideWave',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // කලින් මෙතන තිබ්බේ const LoginScreen() කියලා.
      // දැන් අපි දානවා AuthWrapper කියලා අලුත් එකක්.
      home: const AuthWrapper(),
    );
  }
}

// --- අලුත් කොටස: ලොග් වෙලාද කියලා බලන තැන ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase එකෙන් අහනවා "දැනට කවුරු හරි ඉන්නවද?" කියලා
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // ඩේටා චෙක් කරනකම් පොඩි Loading එකක් පෙන්නනවා
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // snapshot.hasData කියන්නේ කලින් ලොග් වුන කෙනෙක් ඉන්නවා කියන එකයි.
        if (snapshot.hasData) {
          return const MainLayout(); // එහෙනම් කෙලින්ම Home එකට යන්න
        }

        // කවුරුත් නැත්නම් Login එකට යන්න
        return const LoginScreen();
      },
    );
  }
}