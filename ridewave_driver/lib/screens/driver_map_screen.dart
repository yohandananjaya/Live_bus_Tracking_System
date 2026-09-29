import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverMapScreen extends StatefulWidget {
  final String busId; 

  const DriverMapScreen({super.key, required this.busId});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  // 🔥 වෙනස්කම 1: Default Location එක අයින් කළා. දැන් මේක null.
  // GPS අහුවෙනකම් Map එක පෙන්නන්නේ නෑ.
  LatLng? _currentLocation; 
  
  final MapController _mapController = MapController();
  bool _isLiveTracking = false;
  double _currentSpeed = 0.0; // වේගය පෙන්වන්න
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
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, 
      forceLocationManager: true, 
      intervalDuration: const Duration(seconds: 1),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLiveTracking = true;
          _currentSpeed = position.speed * 3.6; // m/s to km/h convert කළා
        });
        
        // Map එක Load වෙලා නම් විතරක් Move කරන්න
        _mapController.move(_currentLocation!, 17.0);
      }

      _updateFirebaseLocation(position);
      
    }, onError: (e) {
      print("Stream Error: $e");
    });
  }

  Future<void> _updateFirebaseLocation(Position position) async {
    try {
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
    if (_currentLocation == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueAccent),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Live Route", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0, bottom: 0,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset('assets/home_bg.jpg', fit: BoxFit.cover),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  Text("Acquiring GPS Signal...", style: TextStyle(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Please wait outside for better signal", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text("Live Tracking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text("Bus ID: ${widget.busId}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isLiveTracking ? Colors.green : Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5))
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.white),
                const SizedBox(width: 5),
                Text(_isLiveTracking ? "ONLINE" : "OFFLINE", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!, // දැන් null වෙන්න බෑ
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ridewave_driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)]
                          ),
                          child: const Text("You", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const Icon(Icons.directions_bus_filled, color: Colors.blue, size: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. BOTTOM INFO CARD (Speed & Status)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                        child: Icon(Icons.speed, color: Colors.blue[800]),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Current Speed", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text("${_currentSpeed.toStringAsFixed(1)} km/h", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                        ],
                      ),
                    ],
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      _mapController.move(_currentLocation!, 18.0);
                    },
                    backgroundColor: Colors.blue[800],
                    mini: true,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
