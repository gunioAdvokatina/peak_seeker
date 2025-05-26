import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:peak_seeker/theme.dart';
import 'package:peak_seeker/config.dart';

class NavigationScreen extends StatefulWidget {
  final GeoPoint? startPoint;
  final String? trailName;

  const NavigationScreen({super.key, this.startPoint, this.trailName});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  Position? _currentPosition;
  String? _error;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(42.018663, 23.105052722),
    zoom: 13,
  );

  // Travel mode
  String _travelMode = 'driving';
  final List<Map<String, dynamic>> _travelModes = [
    {'mode': 'walking', 'label': 'Ходене', 'icon': Icons.directions_walk},
    {'mode': 'driving', 'label': 'Шофиране', 'icon': Icons.directions_car},
    {'mode': 'transit', 'label': 'Транспорт', 'icon': Icons.directions_transit},
  ];

  // Place controllers and coordinates
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  LatLng? _startLatLng;
  LatLng? _endLatLng;

  @override
  void initState() {
    super.initState();
    // Initialize end field if trail data is provided
    if (widget.startPoint != null && widget.trailName != null) {
      _endController.text = widget.trailName!;
      _endLatLng = LatLng(widget.startPoint!.latitude, widget.startPoint!.longitude);
    }
    // Fetch current location and update start field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Услугите за местоположение са изключени.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Правата за достъп до местоположението са отказани.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Правата за достъп до местоположението са отказани завинаги.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (position.latitude < -90 ||
          position.latitude > 90 ||
          position.longitude < -180 ||
          position.longitude >= 180) {
        setState(() {
          _error = 'Невалидни координати от геолокацията.';
        });
        return;
      }
      setState(() {
        _currentPosition = position;
        _startLatLng = LatLng(position.latitude, position.longitude);
        _startController.text = 'Вашето местоположение'; // Immediate fallback
        _resolveCurrentLocationName();
        _updateMap();
      });
    } catch (e) {
      setState(() {
        _error = 'Грешка при извличане на местоположението: ${e.toString()}';
      });
    }
  }

  Future<void> _resolveCurrentLocationName() async {
    if (_currentPosition == null) return;
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
              'latlng=${_currentPosition!.latitude},${_currentPosition!.longitude}&'
              'key=${Config.googleApiKey}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          setState(() {
            _startController.text =
                data['results'][0]['formatted_address'] ?? 'Current Location';
          });
        }
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
      setState(() {
        _startController.text = 'Current Location';
      });
    }
  }

  Future<void> _updateMap() async {
    if (_startLatLng == null) return;

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Add start marker
    markers.add(
      Marker(
        markerId: const MarkerId('start_position'),
        position: _startLatLng!,
        infoWindow: InfoWindow(title: _startController.text),
      ),
    );

    // Add end marker and route
    if (_endLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end_position'),
          position: _endLatLng!,
          infoWindow: InfoWindow(title: _endController.text),
        ),
      );

      try {
        final route = await _fetchRoute(_startLatLng!, _endLatLng!);
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: route,
            color: AppColors.primaryGreen,
            width: 5,
          ),
        );
      } catch (e) {
        print('Routing error: $e');
        polylines.add(
          Polyline(
            polylineId: const PolylineId('fallback'),
            points: [_startLatLng!, _endLatLng!],
            color: AppColors.pastelGreen,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)],
            width: 4,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Move camera
    final controller = await _controller.future;
    if (_endLatLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _startLatLng!.latitude < _endLatLng!.latitude
              ? _startLatLng!.latitude
              : _endLatLng!.latitude,
          _startLatLng!.longitude < _endLatLng!.longitude
              ? _startLatLng!.longitude
              : _endLatLng!.longitude,
        ),
        northeast: LatLng(
          _startLatLng!.latitude > _endLatLng!.latitude
              ? _startLatLng!.latitude
              : _endLatLng!.latitude,
          _startLatLng!.longitude > _endLatLng!.longitude
              ? _startLatLng!.longitude
              : _endLatLng!.longitude,
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else {
      controller.animateCamera(CameraUpdate.newLatLng(_startLatLng!));
    }
  }

  Future<List<LatLng>> _fetchRoute(LatLng origin, LatLng destination) async {
    const apiKey = '${Config.googleApiKey}';
    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=$_travelMode&'
        'key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      throw Exception('Directions API error: ${data['status']}');
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(points);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _debugCoordinates() {
    print('Debugging coordinates:');
    print(
        'Current Position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    print(
        'Start: ${_startController.text}, ${_startLatLng?.latitude}, ${_startLatLng?.longitude}');
    print(
        'End: ${_endController.text}, ${_endLatLng?.latitude}, ${_endLatLng?.longitude}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Start: ${_startController.text}\nEnd: ${_endController.text}',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GooglePlaceAutoCompleteTextField(
            textEditingController: _startController,
            googleAPIKey: '${Config.googleApiKey}',
            inputDecoration: InputDecoration(
              hintText: 'Начало',
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixIcon: _startController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear,
                    color: AppColors.primaryOrange, size: 20),
                onPressed: () {
                  setState(() {
                    _startController.clear();
                    _startLatLng = _currentPosition != null
                        ? LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude)
                        : null;
                    _resolveCurrentLocationName();
                    _updateMap();
                  });
                },
              )
                  : null,
            ),
            debounceTime: 400,
            countries: const ['bg'],
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              if (prediction.lat != null && prediction.lng != null) {
                setState(() {
                  _startLatLng = LatLng(
                      double.parse(prediction.lat!), double.parse(prediction.lng!));
                  _startController.text = prediction.description ?? '';
                  _updateMap();
                });
              }
            },
            itemClick: (Prediction prediction) {
              _startController.text = prediction.description ?? '';
              _startController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _startController.text.length));
            },
            itemBuilder: (context, index, Prediction prediction) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(prediction.description ?? '',
                    style: const TextStyle(fontSize: 14)),
              );
            },
            seperatedBuilder:
            Divider(color: AppColors.primaryOrange.withOpacity(0.2)),
            isCrossBtnShown: false,
          ),
          const SizedBox(height: 6),
          GooglePlaceAutoCompleteTextField(
            textEditingController: _endController,
            googleAPIKey: '${Config.googleApiKey}',
            inputDecoration: InputDecoration(
              hintText: 'Край',
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixIcon: _endController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: AppColors.primaryOrange, size: 20),
                onPressed: () {
                  setState(() {
                    _endController.clear();
                    _endLatLng = null;
                    _updateMap();
                  });
                },
              )
                  : null,
            ),
            debounceTime: 400,
            countries: const ['bg'],
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              if (prediction.lat != null && prediction.lng != null) {
                setState(() {
                  _endLatLng = LatLng(
                      double.parse(prediction.lat!), double.parse(prediction.lng!));
                  _endController.text = prediction.description ?? '';
                  _updateMap();
                });
              }
            },
            itemClick: (Prediction prediction) {
              _endController.text = prediction.description ?? '';
              _endController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _endController.text.length));
            },
            itemBuilder: (context, index, Prediction prediction) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(prediction.description ?? '',
                    style: const TextStyle(fontSize: 14)),
              );
            },
            seperatedBuilder:
            Divider(color: AppColors.primaryOrange.withOpacity(0.2)),
            isCrossBtnShown: false,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _travelModes.map((modeData) {
              final mode = modeData['mode'] as String;
              final label = modeData['label'] as String;
              final icon = modeData['icon'] as IconData;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _travelMode = mode;
                    _updateMap();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: _travelMode == mode
                        ? AppColors.primaryOrange.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _travelMode == mode,
                        onChanged: (bool? value) {
                          if (value == true) {
                            setState(() {
                              _travelMode = mode;
                              _updateMap();
                            });
                          }
                        },
                        activeColor: AppColors.primaryOrange,
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (!states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return AppColors.primaryOrange;
                        }),
                        side: const BorderSide(color: Colors.grey, width: 1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Icon(icon, size: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryOrange,
                          fontWeight: _travelMode == mode
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.pastelGreen,
        appBar: AppBar(
          title: const Text('Навигация', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primaryGreen,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Scaffold(
        backgroundColor: AppColors.pastelGreen,
        appBar: AppBar(
          title: const Text('Навигация', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primaryGreen,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pastelGreen,
      appBar: AppBar(
        title: const Text('Навигация', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _updateMap,
            tooltip: 'Опресни маршрута',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _updateMap();
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildSearchBar(),
          ),
        ],
      ),
    );
  }
}