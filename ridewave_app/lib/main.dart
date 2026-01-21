import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'screens/login_screen.dart';
import 'screens/main_layout.dart'; 

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
      
      home: const AuthWrapper(),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
     
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        
        if (snapshot.hasData) {
          return const MainLayout(); 
        }

        
        return const LoginScreen();
      },
    );
  }
}