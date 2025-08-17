import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location_;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/route/route_constants.dart';

class AddressesScreen extends StatefulWidget {
  final bool showAppBar;       // التحكم بعرض AppBar
  final bool showBackButton;   // التحكم بزر التراجع

  const AddressesScreen({
    Key? key,
    this.showAppBar = true,
    this.showBackButton = true,
  }) : super(key: key);

    @override
    State<AddressesScreen> createState() => AddressesScreenState();
  }


class AddressesScreenState extends State<AddressesScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  location_.Location location = location_.Location();
  location_.LocationData? currentLocation;
  LatLng userLocationMarker = LatLng(0.0, 0.0);
  String addressText = "";
  late BitmapDescriptor customMarker;
  late GoogleMapController mapController;
  TextEditingController addressController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  StreamSubscription<location_.LocationData>? locationSubscription;
  List<dynamic> placeSuggestions = [];
  Timer? _debounce;

  static const String googleMapsApiKey = "AIzaSyA903FiEEzDSEmogbe9-PkmA_v520gnrQ4"; // استخدم مفتاحك هنا

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    fetchLocationFromApi();
  }

  Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(38, 38)),
      'assets/icons/pin.png',
    );
  }

  Future<void> fetchLocationFromApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    if (userId == null) {
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }

    double? savedLatitude = prefs.getDouble('latitude');
    double? savedLongitude = prefs.getDouble('longitude');
    final response = await http.get(Uri.parse('${APIConfig.getaddressEndpoint}$userId/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userLocationMarker = LatLng(
          double.parse(data['x_map']),
          double.parse(data['y_map']),
        );
        addressText = data['address_line'];
        prefs.setDouble('latitude', double.parse(data['x_map']));
        prefs.setDouble('longitude', double.parse(data['y_map']));
      });
    } else {
      if (savedLatitude != null && savedLongitude != null) {
        setState(() {
          userLocationMarker = LatLng(savedLatitude, savedLongitude);
          addressText = 'العنوان غير متوفر';
        });
      } else {
        Position position = await _getCurrentLocation();
        setState(() {
          userLocationMarker = LatLng(position.latitude, position.longitude);
          addressText = '';
        });
      }
    }

    await getCurrentLocation(userLocationMarker.latitude, userLocationMarker.longitude);
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('خدمة الموقع غير مفعلّة');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('إذن الوصول إلى الموقع مرفوض');
    }

    if (permission == LocationPermission.deniedForever) return Future.error('إذن مرفوض دائمًا');

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> getCurrentLocation(double latitude, double longitude) async {
    if (!await location.serviceEnabled() && !await location.requestService()) return;
    if (await location.hasPermission() == location_.PermissionStatus.denied &&
        await location.requestPermission() != location_.PermissionStatus.granted) return;

    setState(() => userLocationMarker = LatLng(latitude, longitude));
    currentLocation = await location.getLocation();
    locationSubscription = location.onLocationChanged.listen((newLoc) {
      setState(() => currentLocation = newLoc);
    });
  }

  Future<void> _updateAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          addressText = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
          addressController.text = addressText;
        });
      }
    } catch (e) {
      print('Error retrieving address: $e');
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _getSuggestions(value));
  }

  Future<void> _getSuggestions(String input) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&language=ar&components=country:sa&key=$googleMapsApiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        placeSuggestions = data['predictions'];
      });
    }
  }

  Future<void> _selectSuggestion(String placeId) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&language=ar&key=$googleMapsApiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));

      setState(() {
        userLocationMarker = LatLng(lat, lng);
        placeSuggestions.clear();
      });

      _updateAddress(lat, lng);
    }
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
       appBar: widget.showAppBar
        ? AppBar(
            title: const Text("تحديد الموقع"),
            leading: widget.showBackButton ? const BackButton() : null,
          )
        : null,
      body: SafeArea(
        child: userLocationMarker.latitude == 0.0 && userLocationMarker.longitude == 0.0
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن موقع...',
                              suffixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                          if (placeSuggestions.isNotEmpty)
                            Container(
                              height: 200,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: placeSuggestions.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(placeSuggestions[index]['description']),
                                    onTap: () => _selectSuggestion(placeSuggestions[index]['place_id']),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: userLocationMarker,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("userLocation"),
                            position: userLocationMarker,
                            icon: customMarker,
                            draggable: false,
                          ),
                        },
                        onMapCreated: (controller) {
                          _controller.complete(controller);
                          mapController = controller;
                        },
                        onCameraMove: (position) => userLocationMarker = position.target,
                        onCameraIdle: () => _updateAddress(userLocationMarker.latitude, userLocationMarker.longitude),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: addressController,
                            decoration: const InputDecoration(hintText: "أدخل العنوان هنا", border: OutlineInputBorder()),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => saveAddress(addressController.text, userLocationMarker.latitude, userLocationMarker.longitude),
                            child: Text("تأكيد العنوان"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize: Size(double.infinity, 50),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 210.0),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            onPressed: _goToCurrentLocation,
            backgroundColor: primaryColor,
            child: Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _goToCurrentLocation() async {
    final controller = await _controller.future;
    if (currentLocation != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!), 16));
    }
  }

  Future<void> saveAddress(String addressLine, double latitude, double longitude) async {
    final url = APIConfig.addressesEndpoint;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId == null) return;

    await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'address_line': addressLine,
          'x_map': latitude,
          'y_map': longitude,
          'user': userId,
        }));

    Navigator.pop(context);
  }
}
