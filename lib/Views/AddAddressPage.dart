import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Address.dart';
import 'package:male/Models/Exceptions.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AddAddressPage extends StatelessWidget {
  String addressName;
  String name;
  String address;
  String phone;
  Completer<GoogleMapController> _controller = Completer();
  ValueNotifier<bool> isLocationGranted = ValueNotifier(false);
  ValueNotifier<bool> isLocationEnabled = ValueNotifier(false);
  ValueNotifier<LatLng> markedPosition = ValueNotifier(null);
  ValueNotifier<String> markedPositionDisplayname = ValueNotifier(null);
  void checkGps()
  {

  }
  void checkPermissions() {

    isLocationServiceEnabled()
        .then((value) {
          print('location service status ${value}');

          isLocationEnabled.value = value;
        });

    Permission.locationWhenInUse.status.then((value) {
      isLocationGranted.value = value.isGranted;
      print('location permission ${value}');
      if (!value.isGranted) {
        Permission.locationWhenInUse.request().then((value) {
          if(value.isUndetermined)
            {
              isLocationGranted.value=true;return;
            }
          isLocationGranted.value = value.isGranted;
        });
      }
    });
  }

  Future<void> gotoPosition(CameraPosition camPos, BuildContext context) async {
    try {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(camPos));
      markedPosition.value = camPos.target;

      placemarkFromCoordinates(
              camPos.target.latitude, camPos.target.longitude)
          .then((value) {
        if (value?.first != null) {
          markedPositionDisplayname.value =
              '${value.first.country}, ${value.first.administrativeArea}, ${value.first.thoroughfare}';
        } else {
          markedPositionDisplayname.value = null;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Widget build(BuildContext context) {
    checkPermissions();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('Add address')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Container(
                height: MediaQuery.of(context).size.height / 2.2,
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      child: ValueListenableBuilder<String>(
                          valueListenable: markedPositionDisplayname,
                          builder: (context, value, child) => Text(
                                value ??
                                    AppLocalizations.of(context)
                                        .translate('Map address'),
                              )),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isLocationEnabled,
                        builder: (context, isLocationEnabled, child) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: isLocationGranted,
                            builder: (context, value, child) {
                              return Stack(
                                children: [
                                  ValueListenableBuilder<LatLng>(
                                    valueListenable: markedPosition,
                                    builder: (context, marker, child) =>
                                        GoogleMap(
                                      markers: marker != null
                                          ? Set<Marker>.from([
                                              Marker(
                                                position: marker,
                                                markerId: MarkerId(
                                                    AppLocalizations.of(context)
                                                        .translate(
                                                            'Delivery address')),
                                                infoWindow: InfoWindow(
                                                  title: AppLocalizations.of(
                                                          context)
                                                      .translate(
                                                          'Delivery address'),
                                                ),
                                                visible: true,
                                              )
                                            ])
                                          : null,
                                      onMapCreated: (controller) =>
                                          _controller.complete(controller),
                                      onTap: (argument) {
                                        gotoPosition(
                                            CameraPosition(
                                              target: argument,
                                              bearing: 180,
                                              tilt: 0,
                                              zoom: 18,
                                            ),
                                            context);
                                      },
                                      myLocationEnabled: true,
                                      mapType: MapType.hybrid,
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(41.638645, 42.987036),
                                        bearing: 180,
                                        tilt: 0,
                                        zoom: 18,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (!value)
                                        Container(
                                          child: Text(AppLocalizations.of(
                                                  context)
                                              .translate(
                                                  'Location permission not granted')),
                                          decoration: BoxDecoration(
                                              color: Colors.grey,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(1))),
                                        ),
                                      if (!isLocationEnabled)
                                        Container(
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'Location not enabled')),
                                          decoration: BoxDecoration(
                                              color: Colors.grey,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(1))),
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      height: 40,
                      child: TextField(
                        onChanged: (value) {
                          addressName = value;
                        },
                        decoration: kOutlineInputText.copyWith(
                            hintText: AppLocalizations.of(context)
                                .translate('Address name(Home, Work..)')),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      height: 40,
                      child: TextField(
                        onChanged: (value) {
                          name = value;
                        },
                        decoration: kOutlineInputText.copyWith(
                            hintText:
                                AppLocalizations.of(context).translate('Name')),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      height: 40,
                      child: TextField(
                        onChanged: (value) {
                          address = value;
                        },
                        decoration: kOutlineInputText.copyWith(
                            hintText: AppLocalizations.of(context)
                                .translate('Address')),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12),
                      height: 40,
                      child: TextField(
                        onChanged: (value) {
                          phone = value;
                        },
                        keyboardType: TextInputType.phone,
                        decoration: kOutlineInputText.copyWith(
                            hintText: AppLocalizations.of(context)
                                .translate('Phone')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 5,
            ),
            Consumer<User>(
              builder: (context, user, child) {
                if (user == null) {
                  return Center(
                    child: Text(
                        AppLocalizations.of(context).translate('Unauthorized')),
                  );
                } else
                  return FlatButton(
                    child: Text(AppLocalizations.of(context).translate('Add')),
                    onPressed: () {
                      try {
                        if ((name?.length ?? 0) < 1) {
                          throw MessageException(AppLocalizations.of(context)
                              .translate('Name field is empty'));
                        }
                        if ((address?.length ?? 0) < 1) {
                          throw MessageException(AppLocalizations.of(context)
                              .translate('Address field is empty'));
                        }
                        if ((phone?.length ?? 0) < 1) {
                          throw MessageException(AppLocalizations.of(context)
                              .translate('Phone field is empty'));
                        }
                        if (markedPosition.value == null) {
                          throw MessageException(AppLocalizations.of(context)
                              .translate(
                                  'The delivery address is not selected on the map'));
                        }
                        var userAddress = UserAddress(
                            uid: user.uid,
                            addressName: addressName,
                            mobileNumber: phone,
                            name: name,
                            address: address,
                            coordinates: Coordinates(
                                latitude: markedPosition.value.latitude,
                                longitude: markedPosition.value.longitude));
                        Navigator.pop<UserAddress>(context, userAddress);
                      } on MessageException catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => OkDialog(
                            title:
                                AppLocalizations.of(context).translate('Error'),
                            content: e.message,
                          ),
                        );
                      }
                    },
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}
