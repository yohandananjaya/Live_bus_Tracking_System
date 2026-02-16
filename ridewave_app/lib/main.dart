import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

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
      title: 'RideWave Passenger',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  Widget _startScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // Passenger කෙනෙක් ලොග් වෙලාද බලනවා (Firebase Auth)
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _startScreen = const MainLayout(); // කෙලින්ම Passenger Home එකට
        _isLoading = false;
      });
    } else {
      setState(() {
        _startScreen = const LoginScreen(); // නැත්නම් Login එකට
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _startScreen;
  }
}