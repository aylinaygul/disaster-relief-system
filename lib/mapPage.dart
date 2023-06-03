import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'formPage.dart';
import 'package:geocoding/geocoding.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(36, -122), // Coordinates for Ankara
    zoom: 14.0,
  );

  Set<Marker> _markers = {}; // Define a Set of Markers
  WeatherFactory _weatherFactory =
      WeatherFactory('10a49ab52ab5d456cb3edfc34844b6aa');
  Weather? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore db = FirebaseFirestore.instance;
    getLocation();
  }

  Future<void> _addMarker(double lat, double lng) async {
    // Create a marker
    Marker marker = Marker(
      markerId: MarkerId('marker'),
      position: LatLng(lat, lng), // Coordinates for Ankara
    );

    setState(() {
      _markers.add(marker); // Add the marker to the Set
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRequest,
        label: const Text('Create Request'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.hybrid,
                    initialCameraPosition: _kGooglePlex,
                    markers:
                        _markers, // Pass the markers Set to the GoogleMap widget
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                  _isLoading
                      ? Center(
                          child: SpinKitFadingCube(
                            color: Colors.blue,
                            size: 50.0,
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.0),
          _buildWeatherInfo(),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    if (_isLoading) {
      return SizedBox();
    } else if (_weather != null) {
      return Column(
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.thermostat_rounded,
                color: Colors.blue,
              ),
              title: Text(
                'Temperature',
                style: TextStyle(fontSize: 20),
              ),
              subtitle: Text(
                '${_weather!.temperature!.celsius?.floor()}°C',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.cloud,
                color: Colors.blue,
              ),
              title: Text(
                'Condition',
                style: TextStyle(fontSize: 20),
              ),
              subtitle: Text(
                '${_weather!.weatherMain}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.cloud_queue,
                color: Colors.blue,
              ),
              title: Text(
                'Description',
                style: TextStyle(fontSize: 20),
              ),
              subtitle: Text(
                '${_weather!.weatherDescription}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Text('Failed to fetch weather data'),
      );
    }
  }

  void _createRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormPage()),
    );
  }

  late Position _currentPosition;
  void getLocation() {
    Geolocator.checkPermission().then((locationPermission) {
      if (locationPermission == LocationPermission.denied) {
        Geolocator.requestPermission().then((permissionRequested) {
          if (permissionRequested == LocationPermission.whileInUse ||
              permissionRequested == LocationPermission.always) {
            _getCurrentLocation();
            // Permission granted. Proceed with using Geolocator.
          }
        });
      } else if (locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always) {
        _getCurrentLocation();

        // Permission already granted. Proceed with using Geolocator.
      }
    });
  }

  int markerid = 0;
  _getCurrentLocation() {
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      forceAndroidLocationManager: true,
    ).then((Position position) {
      setState(() {
        _currentPosition = position;

        // Update the marker position
        Marker mark = Marker(
          markerId: MarkerId(markerid.toString()),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'My Location',
          ),
        );
        _markers.add(mark);

        // Update the camera position without affecting the marker
        CameraPosition cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
        _controller.future.then((GoogleMapController controller) {
          controller
              .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        });
        getLatLng();

        print(_currentPosition.latitude);
        print(_currentPosition.longitude);
        _fetchWeather(_currentPosition.latitude, _currentPosition.longitude);
      });

      markerid++;
    }).catchError((e) {
      print(e);
    });
  }

  Future<void> getLatLng() async {
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('siginmayeri');
    QuerySnapshot querySnapshot = await collectionReference.get();

    querySnapshot.docs.forEach((doc) {
      double latitude = doc.get('enlem');
      double longitude = doc.get('boylam');
      String ad = doc.get('ad');
      String addrss = '';
      getAddressFromLatLng(latitude, longitude).then((String? address) {
        addrss = address ?? '';
      });

      print('Latitude: $latitude');
      print('Longitude: $longitude');
      print(addrss);

      setState(() {
        Marker mark = Marker(
          markerId: MarkerId(markerid.toString()),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: ad + addrss,
          ),
        );
        _markers.add(mark);
      });
      markerid++;
    });
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    try {
      _weather = await _weatherFactory.currentWeatherByLocation(lat, lng);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) {
    return placemarkFromCoordinates(latitude, longitude)
        .then((List<Placemark> placemarks) {
      if (placemarks != null && placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = '${placemark.name ?? ''}, '
            '${placemark.street ?? ''}, '
            '${placemark.locality ?? ''}, '
            '${placemark.administrativeArea ?? ''}, '
            '${placemark.country ?? ''}';

        return address;
      } else {
        return 'No address found';
      }
    }).catchError((e) {
      print("Error: $e");
      return null;
    });
  }
}
