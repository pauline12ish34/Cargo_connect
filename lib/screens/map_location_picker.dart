import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class MapLocationPicker extends StatefulWidget {
  final String title;
  final PickedLocation? initialLocation;

  const MapLocationPicker({
    super.key,
    required this.title,
    this.initialLocation,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  // Default to Kigali city centre
  static const _kigali = LatLng(-1.9441, 30.0619);
  static const _primaryGreen = Color(0xFF08914D);

  late final MapController _mapController;
  LatLng _center = _kigali;
  String _address = 'Move the map to select a location';
  bool _loadingAddress = false;
  bool _fetchingGps = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _center = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _address = widget.initialLocation!.address;
    } else {
      _gotoCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _gotoCurrentLocation() async {
    setState(() => _fetchingGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _address = 'Location access denied — drag the map to pick';
            _fetchingGps = false;
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      _mapController.move(loc, 16);
      if (mounted) setState(() => _center = loc);
      await _reverseGeocode(loc);
    } catch (_) {
      // GPS unavailable — stay on Kigali default
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    setState(() => _center = camera.center);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(camera.center);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${point.latitude}'
        '&lon=${point.longitude}'
        '&zoom=18'
        '&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'CargoLinkApp/1.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final display = data['display_name'] as String?;
        if (mounted) {
          setState(() => _address = display ?? _coordFallback(point));
        }
      } else {
        if (mounted) setState(() => _address = _coordFallback(point));
      }
    } catch (_) {
      if (mounted) setState(() => _address = _coordFallback(point));
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  String _coordFallback(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onPositionChanged: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cargo_app',
              ),
            ],
          ),

          // ── Centre pin ───────────────────────────────────────
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_pin,
                      color: _primaryGreen, size: 52),
                  // Shift up by half the bottom sheet height so the pin
                  // tip sits exactly on the map centre
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── My-location FAB ──────────────────────────────────
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton.small(
              heroTag: 'my_loc',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _fetchingGps ? null : _gotoCurrentLocation,
              child: _fetchingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _primaryGreen),
                    )
                  : const Icon(Icons.my_location, color: _primaryGreen),
            ),
          ),

          // ── Bottom sheet: address + confirm ──────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(blurRadius: 12, color: Colors.black26)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Selected location',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: _primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _loadingAddress
                            ? const Row(children: [
                                SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primaryGreen)),
                                SizedBox(width: 8),
                                Text('Getting address…',
                                    style:
                                        TextStyle(color: Colors.grey)),
                              ])
                            : Text(
                                _address,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loadingAddress
                          ? null
                          : () => Navigator.pop(
                                context,
                                PickedLocation(
                                  latitude: _center.latitude,
                                  longitude: _center.longitude,
                                  address: _address,
                                ),
                              ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Location',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
