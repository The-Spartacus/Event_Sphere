import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:event_sphere/features/profile/logic/profile_controller.dart';
import 'package:event_sphere/core/theme/colors.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _pickedLocation = const LatLng(10.8505, 76.2711); // Default (Kerala)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_pickedLocation),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onTap(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Your Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _determinePosition,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedLocation,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onTap,
                  markers: {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _pickedLocation,
                    ),
                  },
                ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                context.read<ProfileController>().updateLocation(
                      _pickedLocation.latitude,
                      _pickedLocation.longitude,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location saved successfully')),
                );
              },
              child: const Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
