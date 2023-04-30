import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
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

  List<Marker> _markers = <Marker>[];
  late Marker myLocation = const Marker(markerId:MarkerId("myLocation"),position: LatLng(0,0));
  late Position prevPosition;
  @override
  void initState() {
    super.initState();
    initializeMarkers();
    accessLocation();
  }

  void initializeMarkers() async 
  {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref('locations');
    dbRef.onValue.listen((DatabaseEvent event) {
        _markers = [];
        print("Value Changed");
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
    // Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
    //   setState(() async {
    //     final GoogleMapController controller = await _controller.future;
    //     controller.animateCamera(CameraUpdate.newCameraPosition(
    //       CameraPosition(
    //         target: LatLng(position.latitude, position.longitude),
    //         zoom: 14.4746,
    //       ),
    //     ));
    //   });
    // }).catchError((e) {
    //   print(e);
    // });
    Geolocator.getPositionStream().listen((Position position) async {
      print("GOT POSTION");
      final GoogleMapController controller = await _controller.future;
      setState(() {
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.8,
          ),
        ));
        myLocation = Marker(
          markerId: const MarkerId("myLocation"),
          position: LatLng(position.latitude,position.longitude),
          infoWindow: const InfoWindow(
            title: "My Location",
            snippet: "This is my location",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        );
      });
    });
  }

  void addPothole()
  {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
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

  void moveToLocation() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) async {
      final GoogleMapController controller = await _controller.future;
      setState(() {
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.8,
          ),
        ));
        myLocation = Marker(
          markerId: const MarkerId("myLocation"),
          position: LatLng(position.latitude,position.longitude),
          infoWindow: const InfoWindow(
            title: "My Location",
            snippet: "This is my location",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        );
      });
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
        markers: {..._markers,myLocation},
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton.extended(
            onPressed: addPothole,
            label: const Text('Add the Pothole'),
            icon: const Icon(Icons.location_pin),
          ),
          FloatingActionButton.small(
            onPressed: moveToLocation,
            child: const Icon(
              Icons.gps_fixed
            ),
          )
        ],
      ),
    );
  }
}