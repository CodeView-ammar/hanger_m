import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int id;

  const MapScreen({Key? key, required this.latitude, required this.longitude, required this.id}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  loc.LocationData? _currentPosition;
  LatLng curLocation = const LatLng(0.0, 0.0);
  Marker? sourcePosition, destinationPosition;
  StreamSubscription<loc.LocationData>? locationSubscription;
  late BitmapDescriptor customMarker;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker().then((_) {
      _getInitialLocationFromPrefs().then((_) {
        addMarker(); // marker مبدئي من SharedPreferences
        getNavigation(); // الاشتراك في تتبع الموقع
      });
    });
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  /// تحميل أيقونة مخصصة للموقع
  Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(38, 38)),
      'assets/icons/pin.png',
    );
  }

  /// تحميل الموقع المحفوظ من SharedPreferences
  Future<void> _getInitialLocationFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('latitude');
      final lng = prefs.getDouble('longitude');
      if (lat != null && lng != null) {
        setState(() {
          curLocation = LatLng(lat, lng);
        });
      }
    } catch (e) {
      print('Error loading location from prefs: $e');
    }
  }

  /// الاشتراك في تحديثات الموقع وإظهار الطريق
  Future<void> getNavigation() async {
    final controller = await _controller.future;
    final location = loc.Location();
    location.changeSettings(accuracy: loc.LocationAccuracy.high);

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    var permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }

    if (permission == loc.PermissionStatus.granted) {
      _currentPosition = await location.getLocation();
      curLocation = LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!);

      locationSubscription = location.onLocationChanged.listen((loc.LocationData currentLocation) {
        final newLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: newLocation,
          zoom: 16,
        )));
        setState(() {
          curLocation = newLocation;
          sourcePosition = Marker(
            markerId: const MarkerId('source'),
            icon: customMarker,
            position: curLocation,
          );
        });
        getDirections(LatLng(widget.latitude, widget.longitude));
      });
    }
  }

  /// استعلام المسار بين نقطتين
  Future<void> getDirections(LatLng dst) async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      APIConfig.apiMap,
      PointLatLng(curLocation.latitude, curLocation.longitude),
      PointLatLng(dst.latitude, dst.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      addPolyLine(polylineCoordinates);
    } else {
      print("Polyline error: ${result.errorMessage}");
    }
  }

  /// رسم خط المسار
  void addPolyLine(List<LatLng> polylineCoordinates) {
    final id = PolylineId('poly');
    final polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  /// إضافة العلامتين للمصدر والوجهة
  void addMarker() {
    setState(() {
      sourcePosition = Marker(
        markerId: const MarkerId('source'),
        position: curLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
      destinationPosition = Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.latitude, widget.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مسار المغسلة")),
      body: sourcePosition == null || destinationPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  zoomControlsEnabled: false,
                  polylines: Set<Polyline>.of(polylines.values),
                  initialCameraPosition: CameraPosition(
                    target: curLocation,
                    zoom: 16,
                  ),
                  markers: {sourcePosition!, destinationPosition!},
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.navigation_outlined, color: Colors.white),
                      onPressed: () async {
                        final url = Uri.parse(
                            'google.navigation:q=${widget.latitude},${widget.longitude}&key=${APIConfig.apiMap}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          print('Cannot launch Google Maps');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
