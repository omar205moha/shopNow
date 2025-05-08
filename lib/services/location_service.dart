import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Permissions are granted
    return true;
  }

  /// Get the current user location
  Future<LatLng?> getCurrentLocation() async {
    bool permissionGranted = await requestLocationPermission();

    if (!permissionGranted) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  /// Get real-time location updates
  /// Returns a stream of Position objects
  Stream<LatLng> getLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int interval = 5000,
    int distanceFilter = 5,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: const Duration(seconds: 10),
      ),
    ).map((Position position) => LatLng(position.latitude, position.longitude));
  }
}
