import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:u_map/components/umap_directions/directions_model.dart';
import 'package:u_map/components/umap_location/umap_location.dart';
import 'package:u_map/components/umap_location/umap_permissions.dart';
import 'package:u_map/screens/errorscreen/firebase_error_screen.dart';
import 'package:u_map/screens/homescreen/components/umap_icon_button.dart';
import 'package:u_map/size_config.dart';
import 'dart:async';
import 'package:location/location.dart';

class UmapMaps extends StatefulWidget {
  final Directions? directionInformation;
  final String name;
  final String locationID;
  final LatLng locationCoordinates;

  const UmapMaps(
      {Key? key,
      required this.directionInformation,
      required this.name,
      required this.locationID,
      required this.locationCoordinates})
      : super(key: key);

  @override
  _UmapMapsState createState() => _UmapMapsState();
}

class _UmapMapsState extends State<UmapMaps> {
  static final LatLng _center = const LatLng(6.012484, 10.259225);
  final Stream<QuerySnapshot> umapStream =
      FirebaseFirestore.instance.collection('umap_uba').snapshots();
  MapType _currentMapType = MapType.normal;
  GoogleMapController? mapController;
  BitmapDescriptor? mapMarker;
  //final Set<Marker> uMapMarkers = {};
  late Set<Marker> navigationMarker = {};
  LatLng? currentLocation;
  LatLng _lastMapPosition = _center;
  Directions? directionInfo;
  BitmapDescriptor? umapMarkerBig;
  BitmapDescriptor? umapMarkerSmall;
  BitmapDescriptor? umapMarker;

  Set<Marker> setMarkers() {
    navigationMarker.add(
      new Marker(
        flat: false,
        draggable: false,
        zIndex: 5,
        icon: umapMarker ?? BitmapDescriptor.defaultMarker,
        markerId: MarkerId(widget.locationID),
        position: widget.locationCoordinates,
        infoWindow: InfoWindow(title: widget.name),
      ),
    );

    return navigationMarker;
  }

  void setCustomMarker() async {
    umapMarkerBig = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), "assets/images/marker_big.png");
    umapMarkerSmall = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), "assets/images/marker_small.png");
  }

  @override
  initState() {
    //Initialising direction Info
    directionInfo = widget.directionInformation;
    setCustomMarker();
    setMarkers();
    super.initState();
  }

  ///Changing Map Type
  _setCurrentMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  ///getting the current location
  getCurrentLocation() async {
    PermissionStatus? currentPermissionStatus = await getPermissionStatus();
    if (currentPermissionStatus == PermissionStatus.granted) {
      final LocationData currentLocData = await getLocation();
      currentLocation =
          LatLng(currentLocData.latitude!, currentLocData.longitude!);
    }
  }

  _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    Widget? widgetToReturn;

    if (screenWidth * MediaQuery.of(context).devicePixelRatio > 800) {
      umapMarker = umapMarkerBig;
    } else {
      umapMarker = umapMarkerSmall;
    }

    // if (umapMarker == null) {
    //   setState(() {
    //     widgetToReturn = Center(
    //       child: CircularProgressIndicator.adaptive(
    //         valueColor: AlwaysStoppedAnimation<Color>(
    //           Theme.of(context).iconTheme.color!,
    //         ),
    //       ),
    //     );
    //   });
    // } else {
    //   Future.delayed(Duration(seconds: 2), () {
    //     print("future widget is working");
    //   });
    //   print("custim marker is ni=ot null");
    //   Stack(
    //     children: [
    //       GoogleMap(
    //         initialCameraPosition: CameraPosition(
    //           target: _center,
    //           zoom: 17,
    //         ),
    //         mapType: _currentMapType,
    //         markers: setMarkers(),
    //         onCameraMove: _onCameraMove,
    //         myLocationEnabled: true,
    //         polylines: {
    //           if (directionInfo != null)
    //             Polyline(
    //               geodesic: true,
    //               polylineId: const PolylineId('overview_polyline'),
    //               color: Theme.of(context).primaryColor,
    //               width: 6,
    //               zIndex: 1,
    //               endCap: Cap.roundCap,
    //               startCap: Cap.roundCap,
    //               jointType: JointType.bevel,
    //               points: directionInfo!.polylinePoints
    //                   .map((e) => LatLng(e.latitude, e.longitude))
    //                   .toList(),
    //             ),
    //         },
    //       ),
    //       //Change Map Type Button
    //       Positioned(
    //         right: getRelativeScreenWidth(context, 20),
    //         bottom: screenHeight *
    //             .31, // bcs draggable scroll sheet has a min height of .3 of screen height, so it is always above
    //         child: UmapIconButton(
    //           iconLink: "assets/svg/map_change_icon.svg",
    //           onPressed: () {
    //             _setCurrentMapType();
    //           },
    //           bgColor: Theme.of(context).scaffoldBackgroundColor,
    //           iconColor: Theme.of(context).iconTheme.color,
    //         ),
    //       ),
    //     ],
    //   );
    // }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 17,
          ),
          mapType: _currentMapType,
          markers: setMarkers(),
          onCameraMove: _onCameraMove,
          myLocationEnabled: true,
          polylines: {
            if (directionInfo != null)
              Polyline(
                geodesic: true,
                polylineId: const PolylineId('overview_polyline'),
                color: Theme.of(context).primaryColor,
                width: 6,
                zIndex: 1,
                endCap: Cap.roundCap,
                startCap: Cap.roundCap,
                jointType: JointType.bevel,
                points: directionInfo!.polylinePoints
                    .map((e) => LatLng(e.latitude, e.longitude))
                    .toList(),
              ),
          },
        ),
        //Change Map Type Button
        Positioned(
          right: getRelativeScreenWidth(context, 20),
          bottom: screenHeight *
              .31, // bcs draggable scroll sheet has a min height of .3 of screen height, so it is always above
          child: UmapIconButton(
            iconLink: "assets/svg/map_change_icon.svg",
            onPressed: () {
              _setCurrentMapType();
            },
            bgColor: Theme.of(context).scaffoldBackgroundColor,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        ),
      ],
    );
  }
}
