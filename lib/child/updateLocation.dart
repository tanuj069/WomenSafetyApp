import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LocationTracker extends StatefulWidget {
  @override
  _LocationTrackerState createState() => _LocationTrackerState();
}

class _LocationTrackerState extends State<LocationTracker> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateLocation() async {
    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    // Update Firestore with the current location
    await _firestore.collection('locations').doc('user123').set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now(),
    });

    print('Location updated successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Location Tracker'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _updateLocation,
          child: Text('Update Location'),
        ),
      ),
    );
  }
}
