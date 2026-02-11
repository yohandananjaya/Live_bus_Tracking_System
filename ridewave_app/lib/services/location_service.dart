import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // 1. Singleton Pattern (හැම තැනම එකම Instance එකක් පාවිච්චි කරන්න)
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  bool isTripActive = false;
  String? currentBusId;

  // --- 2. Trip Start Function ---
  Future<bool> startTrip(String busId) async {
    // A. Permission ඉල්ලනවා
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Permission දුන්නේ නෑ
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false; // Permission සදහටම නවත්තලා
    }

    // B. Trip එක Active කරනවා
    isTripActive = true;
    currentBusId = busId;

    // C. Location Settings (බැටරි ඉතුරු කරගන්න Settings)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // උපරිම නිවැරදි බව
      distanceFilter: 10, // මීටර් 10ක් යනකම් අප්ඩේට් වෙන්නේ නෑ
    );

    // D. Location Stream එක පටන් ගන්නවා
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        print("📍 Location Update: ${position.latitude}, ${position.longitude}");
        
        if (currentBusId != null) {
          // Firestore එකට යවනවා
          FirebaseFirestore.instance.collection('buses').doc(currentBusId).update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'status': 'Live', // බස් එක Live කියලා දානවා
            'heading': position.heading, // බස් එක යන දිශාව (Optional)
            'speed': position.speed, // වේගය (Optional)
            'lastUpdated': FieldValue.serverTimestamp(),
          }).catchError((error) {
            print("Failed to update location: $error");
          });
        }
      },
      onError: (e) {
        print("Location Stream Error: $e");
      }
    );

    return true; // සාර්ථකයි
  }

  // --- 3. Trip Stop Function ---
  Future<void> stopTrip() async {
    // Stream එක නවත්තනවා
    await _positionStream?.cancel();
    _positionStream = null;
    isTripActive = false;
    
    // අන්තිමට Status එක 'Idle' කරනවා
    if (currentBusId != null) {
      await FirebaseFirestore.instance.collection('buses').doc(currentBusId).update({
        'status': 'Idle',
      });
      currentBusId = null;
    }
  }
}