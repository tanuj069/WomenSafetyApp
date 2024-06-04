import 'package:background_sms/background_sms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:women_safety_app/db/db_services.dart';
import 'package:women_safety_app/model/contactsm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geodesy/geodesy.dart';
import 'package:women_safety_app/utils/flutter_background_services.dart';

class SafeHome extends StatefulWidget {
  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  Position? _curentPosition;
  String? _curentAddress;
  LocationPermission? permission;
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  

  _isPermissionGranted() async => await Permission.sms.status.isGranted;
  

  Future<void> _saveLiveLocationToFirestore() async {
    try {
      // Save live location data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'live_location': {
          'latitude': _curentPosition!.latitude,
          'longitude': _curentPosition!.longitude,
          'current_address':_curentAddress,
          // Add more fields as needed (e.g., timestamp)
        },
      }, SetOptions(merge: true)); // Merge with existing data if any
    } catch (e) {
      print('Error saving live location to Firestore: $e');
    }
  }

  


_sendSms(String phoneNumber, String message, String userId, {int? simSlot}) async {
  // Send SMS
  SmsStatus result = await BackgroundSms.sendMessage(
      phoneNumber: phoneNumber, message: message, simSlot: 1);
  
  // Save live location to Firestore if SMS is sent successfully
  if (result == SmsStatus.sent) {
    try {
      // Save live location data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'live_location': {
          'latitude': _curentPosition!.latitude,
          'longitude': _curentPosition!.longitude,
          'current_address':_curentAddress,
          // Add more fields as needed (e.g., timestamp)
        },
      }, SetOptions(merge: true)); // Merge with existing data if any
    } catch (e) {
      print('Error saving live location to Firestore: $e');
    }
  }

  // Display toast message based on SMS status
  if (result == SmsStatus.sent) {
    print("Sent");
    Fluttertoast.showToast(msg: "send");
  } else {
    Fluttertoast.showToast(msg: "failed");
  }
}
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _curentPosition = position;
        print(_curentPosition!.latitude);
        _getAddressFromLatLon();
      });
    }).catchError((e) {
      Fluttertoast.showToast(msg: e.toString());
    });
  }

  _sendSafeMessage() async {
    String messageBody = "I am safe now. Thank you for your support.";

    // Retrieve phone numbers from Firestore
    QuerySnapshot<Map<String, dynamic>> usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    // Create a list to store phone numbers
    List<String> phoneNumbers = [];

    // Add phone numbers to the list
    usersSnapshot.docs.forEach((userDoc) {
      String phoneNumber = userDoc['phone'];
      phoneNumbers.add(phoneNumber);
      print("Retrieved phone number from Firestore: $phoneNumber");
    });
    print("List of phone numbers: $phoneNumbers");

    // Send safe message to emergency contacts
    List<TContact> contactList = await DatabaseHelper().getContactList();
    if (contactList.isNotEmpty) {
      for (TContact contact in contactList) {
        _sendSms(contact.number, messageBody, userId!);
      }
    } else {
      Fluttertoast.showToast(msg: "Emergency contact list is empty");
    }

    // Send safe message to registered users from Firestore
    if (phoneNumbers.isNotEmpty) {
      for (String phoneNumber in phoneNumbers) {
        _sendSms(phoneNumber, messageBody, userId!);
      }
    } else {
      print("No registered users found in Firestore");
    }
  }



  _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _curentPosition!.latitude, _curentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _curentAddress =
            "${place.locality},${place.postalCode},${place.street},";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
_sendAlertMessage() async {
  // Get current user's location
  if (_curentPosition == null) {
    Fluttertoast.showToast(msg: "Location not available");
    return;
  }

  // Construct message body with location details
  String messageBody =
      "I am in trouble. Location: https://www.google.com/maps/search/?api=1&query=${_curentPosition!.latitude}%2C${_curentPosition!.longitude}. $_curentAddress";

  // Retrieve emergency contacts from local database
  List<TContact> contactList = await DatabaseHelper().getContactList();

  // Send alert to emergency contacts
  if (contactList.isNotEmpty) {
    for (TContact contact in contactList) {
      _sendSms(contact.number, messageBody, userId!);
    }
  } else {
    Fluttertoast.showToast(msg: "Emergency contact list is empty");
  }

  // Retrieve registered users from Firestore
  QuerySnapshot<Map<String, dynamic>> usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();

  // Create a list to store phone numbers of nearby registered users
  List<String> nearbyUserPhoneNumbers = [];

  // Calculate distance and filter nearby registered users within 100 meters
  if (usersSnapshot.docs.isNotEmpty) {
    Geodesy geodesy = Geodesy();
    LatLng currentLatLng = LatLng(_curentPosition!.latitude, _curentPosition!.longitude);
    double maxDistance = 100; // Maximum distance in meters

    usersSnapshot.docs.forEach((userDoc) {
      String phoneNumber = userDoc['phone'];
      double userLat = userDoc['live_location']['latitude'];
      double userLng = userDoc['live_location']['longitude'];

      LatLng userLatLng = LatLng(userLat, userLng);
      double distance = geodesy.distanceBetweenTwoGeoPoints(currentLatLng, userLatLng) as double;

      if (distance <= maxDistance) {
        nearbyUserPhoneNumbers.add(phoneNumber);
      }
    });

    // Send alert to nearby registered users
    if (nearbyUserPhoneNumbers.isNotEmpty) {
      for (String phoneNumber in nearbyUserPhoneNumbers) {
        _sendSms(phoneNumber, messageBody, userId!);
      }
    } else {
      Fluttertoast.showToast(msg: "No registered users found within 100 meters");
    }
  } else {
    print("No registered users found in Firestore");
  }
}

_sendMessage() async {
  // Get current user's location
  if (_curentPosition == null) {
    Fluttertoast.showToast(msg: "Location not available");
    return;
  }

  // Construct message body with location details
  String messageBody =
      "I am safe now. Thankyou for your support";

  // Retrieve emergency contacts from local database
  List<TContact> contactList = await DatabaseHelper().getContactList();

  // Send alert to emergency contacts
  if (contactList.isNotEmpty) {
    for (TContact contact in contactList) {
      _sendSms(contact.number, messageBody, userId!);
    }
  } else {
    Fluttertoast.showToast(msg: "Emergency contact list is empty");
  }

  // Retrieve registered users from Firestore
  QuerySnapshot<Map<String, dynamic>> usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();

  // Create a list to store phone numbers of nearby registered users
  List<String> nearbyUserPhoneNumbers = [];

  // Calculate distance and filter nearby registered users within 100 meters
  if (usersSnapshot.docs.isNotEmpty) {
    Geodesy geodesy = Geodesy();
    LatLng currentLatLng = LatLng(_curentPosition!.latitude, _curentPosition!.longitude);
    double maxDistance = 100; // Maximum distance in meters

    usersSnapshot.docs.forEach((userDoc) {
      String phoneNumber = userDoc['phone'];
      double userLat = userDoc['live_location']['latitude'];
      double userLng = userDoc['live_location']['longitude'];

      LatLng userLatLng = LatLng(userLat, userLng);
      double distance = geodesy.distanceBetweenTwoGeoPoints(currentLatLng, userLatLng) as double;

      if (distance <= maxDistance) {
        nearbyUserPhoneNumbers.add(phoneNumber);
      }
    });

    // Send alert to nearby registered users
    if (nearbyUserPhoneNumbers.isNotEmpty) {
      for (String phoneNumber in nearbyUserPhoneNumbers) {
        _sendSms(phoneNumber, messageBody, userId!);
      }
    } else {
      Fluttertoast.showToast(msg: "No registered users found within 100 meters");
    }
  } else {
    print("No registered users found in Firestore");
  }
}




  @override
  void initState() {
    super.initState();

    _getCurrentLocation();
  }

  showModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 1.4,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SEND YOUR CUURENT LOCATION IMMEDIATELY TO YOU EMERGENCY CONTACTS",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                if (_curentPosition != null) Text(_curentAddress!),
                PrimaryButton(
  title: "GET LOCATION",
  onPressed: () {
    _getCurrentLocation();
    _saveLiveLocationToFirestore();
  }),
SizedBox(height: 10),
PrimaryButton(
  title: "SEND ALERT",
  onPressed: () {
    _sendAlertMessage();
  }
),


SizedBox(height: 10),
                PrimaryButton(
                  title: "HELP RECEIVED",
                  onPressed: () {
                    //_sendSafeMessage();
                    _sendMessage();
                  },
                ),

                

              ],
            ),
          ),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModelSafeHome(context),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  ListTile(
                    title: Text("Send Location"),
                    subtitle: Text("Share Location"),
                  ),
                ],
              )),
              ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/route.jpg')),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String title;
  final Function onPressed;
  bool loading;
  PrimaryButton(
      {required this.title, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width * 0.5,
      child: ElevatedButton(
        onPressed: () {
          onPressed();
        },
        child: Text(
          title,
          style: TextStyle(fontSize: 17),
        ),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30))),
      ),
    );
  }
}
