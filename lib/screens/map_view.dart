import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {

  FirebaseDatabase db = FirebaseDatabase.instance;

  static CameraPosition currentLocation = const CameraPosition(
    target: LatLng(7, 9),
    zoom: 14.4746,
  );

  final List<Marker> _markers = <Marker>[];

  @override
  void initState() {
    super.initState();
    initializeMarkers();
    accessLocation();
  }

  void initializeMarkers() async 
  {
    DatabaseReference starCountRef = FirebaseDatabase.instance.ref('locations');
    starCountRef.onValue.listen((DatabaseEvent event) {
        Map? data = event.snapshot.value as Map;
        Iterable keys = data.keys;
        for (var key in keys) {
          var marker = data[key];
          Marker newMarker = Marker(
            markerId: MarkerId(marker["latitude"].toString()),
            position: LatLng(marker["latitude"],marker["longitude"]),
            infoWindow: const InfoWindow(
              title: "Pothole",
              snippet: "This is a pothole",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          );
          setState(() {
            _markers.add(newMarker);
          });
        }
    });
  }

  void accessLocation() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
      setState(() async {
        print("POSITION");
        print(position);
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.4746,
          ),
        ));
        });
    }).catchError((e) {
      print(e);
    });
  }

  void addPothole()
  {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
    // ignore: unnecessary_new
      Marker marker = Marker(
        markerId: MarkerId(position.latitude.toString()),
        position: LatLng(position.latitude,position.longitude),
        infoWindow: const InfoWindow(
          title: "Pothole",
          snippet: "This is a pothole",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      );

      setMarkerToDB(marker.position);
      
      setState(() {
        _markers.add(marker);
      });
    });
  }

  void setMarkerToDB(LatLng position)
  {
    String id = "marker_${_markers.length+1}";
    db.ref("locations").child(id).set({
      "latitude": position.latitude,
      "longitude": position.longitude,
    });
  }

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: currentLocation,
        markers: Set<Marker>.of(_markers),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(

        onPressed: addPothole,
        label: const Text('Add the Pothole'),
        icon: const Icon(Icons.location_pin),
      ),
    );
  }
}