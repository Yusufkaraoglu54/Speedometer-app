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
      debugShowCheckedModeBanner: false,
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
  double _totalRange = 25.0; // Total range in km (initial value)
  static const double _maxSpeed = 35; // Max speed for the speedometer in km/h
  final TextEditingController _rangeController = TextEditingController(); // TextField controller

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _location.changeSettings(interval: 5000, accuracy: LocationAccuracy.high);
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (_currentLocation != null) {
        // Calculate the distance
        double distance = _calculateDistance(
          _previousLatitude,
          _previousLongitude,
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        setState(() {
          _totalDistance += distance;
          _distanceSinceReset += distance;
          _currentSpeed = currentLocation.speed != null && currentLocation.speed! > 0.1
              ? currentLocation.speed! * 3.6 // Convert from m/s to km/h
              : 0;
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

  double _calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
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

  void _showRangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Menzili Ayarla'),
          content: TextField(
            controller: _rangeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Yeni toplam menzil girin (km)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without doing anything
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _totalRange = double.tryParse(_rangeController.text) ?? _totalRange;
                });
                Navigator.of(context).pop(); // Close the dialog after setting the new range
              },
              child: const Text('Ayarla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double remainingRange = _totalRange - (_totalDistance / 1000); // Remaining distance in km
    double progress = (_totalDistance / 1000) / _totalRange; // Progress percentage (0 to 1)

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(flex: 1, child: Image.asset("resimler/speedometer.jpg")),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(left: 0.1),
                child: Text(
                  "SpeedoMeter",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFAD956),
                      fontSize: 50),
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 100,
        backgroundColor: const Color.fromRGBO(131, 88, 37, 1),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Anlık Hız: ${_currentSpeed.toStringAsFixed(1)} km/h'),
            const SizedBox(height: 20),
            _buildSpeedometer(),
            const SizedBox(height: 20),
            Text(
                'Toplam Kat Edilen Mesafe: ${(_totalDistance / 1000).toStringAsFixed(1)} km'),
            const SizedBox(height: 20),
            Text(
                'Sıfırladıktan Sonra Kat Edilen Mesafe: ${(_distanceSinceReset / 1000).toStringAsFixed(1)} km'),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: _resetDistance,
                child: const Text('Mesafeyi Sıfırla'),
              ),
            ),
            const SizedBox(height: 20),
            _buildRangeIndicator(remainingRange, progress),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showRangeDialog,
              child: const Text('Menzili Ayarla'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the speedometer
  Widget _buildSpeedometer() {
    return TweenAnimationBuilder(
      tween: Tween<double>(
          begin: 0, end: min(_currentSpeed, _maxSpeed) / _maxSpeed),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Circular speedometer background
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
            // Speedometer needle
            Transform.rotate(
              angle: pi * (value - 0.5), // Rotate the needle
              child: Container(
                width: 80,
                height: 5,
                color: Colors.red,
              ),
            ),
            Positioned(
              bottom: 20,
              child: Text('${_currentSpeed.toStringAsFixed(1)} km/h',
                  style: const TextStyle(fontSize: 20)),
            ),
          ],
        );
      },
    );
  }

  // Widget for the remaining range progress bar
  Widget _buildRangeIndicator(double remainingRange, double progress) {
    return Column(
      children: [
        Text('Kalan Menzil: ${remainingRange.toStringAsFixed(1)} km'),
        const SizedBox(height: 10),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: progress, // Value from 0 to 1
            minHeight: 10,
            backgroundColor: Colors.green,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
        const SizedBox(height: 10),
        Text('Menzilin %${(progress * 100).toStringAsFixed(1)} tamamlandı'),
      ],
    );
  }
}
