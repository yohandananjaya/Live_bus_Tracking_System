import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/driver/driver_dashboard.dart'; // Import Driver Dashboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideWave',
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: const LoginScreen(), <-- මේක අයින් කරන්න. අපි තීරණය කරනවා යන්න ඕනේ කොහාටද කියලා.
      home: const AuthCheck(), // අලුත් Widget එක
    );
  }
}

// මේකෙන් තමයි Check කරන්නේ කොහාටද යවන්න ඕනේ කියලා
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  Widget _startScreen = const LoginScreen(); // Default

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // 1. Check Driver Login (Shared Preferences)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDriver = prefs.getBool('isDriverLoggedIn') ?? false;
    String? driverBusId = prefs.getString('driverBusId');

    if (isDriver && driverBusId != null) {
      // Driver කෙනෙක් නම් Dashboard එකට යවන්න
      setState(() {
        _startScreen = DriverDashboard(busId: driverBusId);
        _isLoading = false;
      });
      return;
    }

    // 2. Check Passenger Login (Firebase Auth)
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Passenger කෙනෙක් නම් Main Layout එකට යවන්න
      setState(() {
        _startScreen = const MainLayout();
        _isLoading = false;
      });
      return;
    }

    // 3. කවුරුත් නැත්නම් Login Screen
    setState(() {
      _startScreen = const LoginScreen();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _startScreen;
  }
}