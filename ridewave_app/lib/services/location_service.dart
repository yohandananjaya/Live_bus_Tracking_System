import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  bool isTripActive = false;
  String? currentBusId;

  // Trip Start Function
  Future<bool> startTrip(String busId) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    isTripActive = true;
    currentBusId = busId;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        print("📍 Update: ${position.latitude}, ${position.longitude} -> Bus: $busId");
        
        if (currentBusId != null) {
          FirebaseFirestore.instance.collection('buses').doc(currentBusId).update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'status': 'Live',
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

    return true;
  }

  // Trip Stop Function
  Future<void> stopTrip() async {
    await _positionStream?.cancel();
    _positionStream = null;
    isTripActive = false;
    
    if (currentBusId != null) {
      await FirebaseFirestore.instance.collection('buses').doc(currentBusId).update({
        'status': 'Idle',
      });
      currentBusId = null;
    }
  }
}