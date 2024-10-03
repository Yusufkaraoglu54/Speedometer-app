import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationTrackingPage(),
    );
  }
}

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  _LocationTrackingPageState createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  final Location _location = Location();
  LocationData? _currentLocation;
  double _totalDistance = 0;
  double _distanceSinceReset = 0;
  double _previousLatitude = 0;
  double _previousLongitude = 0;
  double _currentSpeed = 0;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_currentLocation != null) {
        // Mesafe hesaplama
        double distance = _calculateDistance(
          _previousLatitude,
          _previousLongitude,
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        setState(() {
          _totalDistance += distance;
          _distanceSinceReset += distance;
          _currentSpeed = currentLocation.speed ?? 0;
        });
      }
      _currentLocation = currentLocation;
      _previousLatitude = currentLocation.latitude!;
      _previousLongitude = currentLocation.longitude!;
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
  }

  double _calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const double radius = 6371000; // Earth's radius in meters
    double dLat = _degreeToRadian(endLat - startLat);
    double dLng = _degreeToRadian(endLng - startLng);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreeToRadian(startLat)) *
            cos(_degreeToRadian(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c; // Distance in meters
  }

  double _degreeToRadian(double degree) {
    return degree * (pi / 180);
  }

  void _resetDistance() {
    setState(() {
      _distanceSinceReset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hız ve Mesafe Takibi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Anlık Hız: ${_currentSpeed.toStringAsFixed(2)} m/s'),
            const SizedBox(height: 20),
            Text('Toplam Kat Edilen Mesafe: ${(_totalDistance / 1000).toStringAsFixed(2)} km'),
            const SizedBox(height: 20),
            Text('Sıfırladıktan Sonra Kat Edilen Mesafe: ${(_distanceSinceReset / 1000).toStringAsFixed(2)} km'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetDistance,
              child: const Text('Mesafeyi Sıfırla'),
            ),
          ],
        ),
      ),
    );
  }
}
