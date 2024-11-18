import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/adoptionpost_model.dart';
import '../components/adoption_post.dart';

class NearbyReportsScreen extends StatefulWidget {
  const NearbyReportsScreen({Key? key}) : super(key: key);

  @override
  _NearbyReportsScreenState createState() => _NearbyReportsScreenState();
}

class _NearbyReportsScreenState extends State<NearbyReportsScreen> {
  LatLng? _currentPosition;
  String _currentAddress = 'Getting location...';
  List<AdoptionPost> _nearbyReports = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final placemark = placemarks.first;

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _currentAddress = _formatAddress(placemark);
    });

    _fetchNearbyReports();
  }

  String _formatAddress(Placemark placemark) {
    return [
      if (placemark.street != null && placemark.street!.isNotEmpty) placemark.street,
      if (placemark.locality != null && placemark.locality!.isNotEmpty) placemark.locality,
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) placemark.administrativeArea,
      if (placemark.country != null && placemark.country!.isNotEmpty) placemark.country,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
  }

  Future<void> _fetchNearbyReports() async {
    if (_currentPosition == null) return;

    final querySnapshot = await FirebaseFirestore.instance.collection('adoptions').get();
    final allReports = querySnapshot.docs.map((doc) => AdoptionPost.fromMap(doc.data() as Map<String, dynamic>)).toList();

    final nearbyReports = allReports.where((report) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        report.latitude,
        report.longitude,
      );
      return distance <= 1000; // 1 km range
    }).toList();

    setState(() {
      _nearbyReports = nearbyReports;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text('Nearby Reports'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
        titleTextStyle: const TextStyle(color: Color(0xFF6C63FF), fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            'Current Location: $_currentAddress',
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _nearbyReports.length,
                      itemBuilder: (context, index) {
                        final report = _nearbyReports[index];
                        return AdoptionPostWidget(post: report);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}