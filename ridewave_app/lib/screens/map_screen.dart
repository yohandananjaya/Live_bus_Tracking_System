import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Location පැකේජය

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _myLocation; // මගේ Location එක

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // ඇප් එක පටන් ගද්දිම Location හොයනවා
  }

  // අපේ Location එක ගන්න Function එක
  Future<void> _getCurrentLocation() async {
    try {
      // අවසර තියෙනවද බලනවා
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Location ගන්නවා
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Map එක Update කරනවා
      if (mounted) {
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
        // අපේ තැනට Map එක හරවනවා
        _mapController.move(_myLocation!, 15.0);
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 වෙනස් කළ තැන: Button එක Navigation Bar එකට උඩින් පේන්න Padding දැම්මා
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton(
          backgroundColor: Colors.blue[800], // පාට වෙනස් කළා
          onPressed: _getCurrentLocation, 
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buses')
            .where('status', isEqualTo: 'Live')
            .snapshots(),
        builder: (context, snapshot) {
          
          // 1. Bus Markers හදාගන්නවා
          List<Marker> markers = [];
          
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              double lat = (data['latitude'] ?? 0.0).toDouble();
              double lng = (data['longitude'] ?? 0.0).toDouble();

              markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                ),
              );
            }
          }

          // 2. User Location Marker එක එකතු කරනවා (රතු පාටින්)
          if (_myLocation != null) {
            markers.add(
              Marker(
                point: _myLocation!,
                width: 50,
                height: 50,
                child: const Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 40),
                  ],
                ),
              ),
            );
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? const LatLng(6.9271, 79.8612), // Location නැත්නම් කොළඹ
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ridewave_app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}