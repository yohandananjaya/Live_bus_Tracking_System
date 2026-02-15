import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase

class DriverMapScreen extends StatefulWidget {
  // වෙනස්කම: Bus ID එක එළියෙන් බාරගන්නවා
  final String busId; 

  const DriverMapScreen({super.key, required this.busId});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  LatLng _currentLocation = const LatLng(6.9271, 79.8612);
  final MapController _mapController = MapController();
  bool _isLiveTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable Location Services')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _startLiveTracking();
  }

  void _startLiveTracking() {
    // 1. Android Settings (Lockito Compatible)
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, 
      forceLocationManager: true, 
      intervalDuration: const Duration(seconds: 1),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      // A. UI Update
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLiveTracking = true;
        });
        _mapController.move(_currentLocation, 17.0);
      }

      // B. Firebase Update (වෙනස්කම: මෙතනින් Firebase එකට යවනවා)
      _updateFirebaseLocation(position);
      
    }, onError: (e) {
      print("Stream Error: $e");
    });
  }

  // --- Firebase Update Function ---
  Future<void> _updateFirebaseLocation(Position position) async {
    try {
      // widget.busId කියන්නේ Dashboard එකෙන් එවපු ID එක
      await FirebaseFirestore.instance.collection('buses').doc(widget.busId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': true,
      });
    } catch (e) {
      print("Firebase Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map Route"),
        backgroundColor: Colors.orange,
        actions: [
          Icon(_isLiveTracking ? Icons.cloud_upload : Icons.cloud_off, 
               color: _isLiveTracking ? Colors.white : Colors.red),
          const SizedBox(width: 15),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ridewave_driver',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation,
                width: 60,
                height: 60,
                child: const Column(
                  children: [
                    Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                    Text("Me", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}