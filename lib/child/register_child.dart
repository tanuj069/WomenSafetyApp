import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_app/child/bottom_page.dart';
import 'package:women_safety_app/child/child_login_screen.dart';
import 'package:women_safety_app/model/user_model.dart';
import 'package:women_safety_app/utils/constants.dart';
import '../components/PrimaryButton.dart';
import '../components/SecondaryButton.dart';
import '../components/custom_textfield.dart';

import 'package:geolocator/geolocator.dart';

class RegisterChildScreen extends StatefulWidget {
  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
   bool isPasswordShown = true;
  bool isRetypePasswordShown = true;

  final _formKey = GlobalKey<FormState>();

  final _formData = Map<String, Object>();
  bool isLoading = false;

 _onSubmit() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    progressIndicator(context);
    try {
      setState(() {
        isLoading = true;
      });
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _formData['cemail'].toString(),
              password: _formData['password'].toString());
      if (userCredential.user != null) {
        final v = userCredential.user!.uid;
        DocumentReference<Map<String, dynamic>> db =
            FirebaseFirestore.instance.collection('users').doc(v);

        final user = UserModel(
          name: _formData['name'].toString(),
          phone: _formData['phone'].toString(),
          childEmail: _formData['cemail'].toString(),
          id: v,
        );
        final jsonData = user.toJson();
        await db.set(jsonData).whenComplete(() async {
          // Store live location of the user
          await _storeLiveLocation(v);
          goTo(context, BottomPage());
          setState(() {
            isLoading = false;
          });
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        dialogueBox(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        dialogueBox(context, 'The account already exists for that email.');
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e);
      dialogueBox(context, e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }
}

  Future<void> _storeLiveLocation(String userId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'liveLocation': geoPoint});
    } catch (e) {
      print('Error storing live location: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            children: [
              isLoading
                  ? progressIndicator(context)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "REGISTER AS CHILD",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor),
                                ),
                                Image.asset(
                                  'assets/logo.png',
                                  height: 100,
                                  width: 100,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.75,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  CustomTextField(
                                    hintText: 'enter name',
                                    textInputAction: TextInputAction.next,
                                    keyboardtype: TextInputType.name,
                                    prefix: Icon(Icons.person),
                                    onsave: (name) {
                                      _formData['name'] = name ?? "";
                                    },
                                    validate: (name) {
                                      if (name!.isEmpty) {
                                        return 'enter name';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'enter phone number',
                                    textInputAction: TextInputAction.next,
                                    keyboardtype: TextInputType.phone,
                                    prefix: Icon(Icons.phone),
                                    onsave: (phone) {
                                      _formData['phone'] = phone ?? "";
                                    },
                                    validate: (phone) {
                                      if (phone!.isEmpty) {
                                        return 'enter phone number';
                                      } else if (phone.length < 10) {
                                        return 'enter correct phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'enter  email',
                                    textInputAction: TextInputAction.next,
                                    keyboardtype: TextInputType.emailAddress,
                                    prefix: Icon(Icons.person),
                                    onsave: (cemail) {
                                      _formData['cemail'] = cemail ?? "";
                                    },
                                    validate: (cemail) {
                                      if (cemail!.isEmpty ||
                                          cemail.length < 3 ||
                                          !cemail.contains("@")) {
                                        return 'enter correct email';
                                      }
                                    },
                                  ),
                                  // CustomTextField(
                                  //   hintText: 'enter guardian email',
                                  //   textInputAction: TextInputAction.next,
                                  //   keyboardtype: TextInputType.emailAddress,
                                  //   prefix: Icon(Icons.person),
                                  //   onsave: (gemail) {
                                  //     _formData['gemail'] = gemail ?? "";
                                  //   },
                                  //   validate: (gemail) {
                                  //     if (gemail!.isEmpty ||
                                  //         gemail.length < 3 ||
                                  //         !gemail.contains("@")) {
                                  //       return 'enter correct email';
                                  //     }
                                  //   },
                                  // ),
                                  CustomTextField(
                                    hintText: 'enter password',
                                    isPassword: isPasswordShown,
                                    prefix: Icon(Icons.vpn_key_rounded),
                                    validate: (password) {
                                      if (password!.isEmpty ||
                                          password.length < 5) {
                                        return 'password length should be of minimum 5 characters';
                                      }
                                      return null;
                                    },
                                    onsave: (password) {
                                      _formData['password'] = password ?? "";
                                    },
                                    suffix: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            isPasswordShown = !isPasswordShown;
                                          });
                                        },
                                        icon: isPasswordShown
                                            ? Icon(Icons.visibility_off)
                                            : Icon(Icons.visibility)),
                                  ),
                                  // CustomTextField(
                                  //   hintText: 'retype password',
                                  //   isPassword: isRetypePasswordShown,
                                  //   prefix: Icon(Icons.vpn_key_rounded),
                                  //   validate: (rpassword) {
                                  //     if (rpassword!.isEmpty ||
                                  //         rpassword.length < 5) {
                                  //       return 'password do not match';
                                  //     }
                                  //     return null;
                                  //   },
                                  //   onsave: (rpassword) {
                                  //     _formData['rpassword'] = rpassword ?? "";
                                  //   },
                                  //   suffix: IconButton(
                                  //       onPressed: () {
                                  //         setState(() {
                                  //           isRetypePasswordShown =
                                  //               !isRetypePasswordShown;
                                  //         });
                                  //       },
                                  //       icon: isRetypePasswordShown
                                  //           ? Icon(Icons.visibility_off)
                                  //           : Icon(Icons.visibility)),
                                  // ),
                                  PrimaryButton(
                                      title: 'REGISTER',
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _onSubmit();
                                        }
                                      }),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have account?",style: TextStyle(fontSize: 16),),
                              SecondaryButton(
                                  title: 'Login',
                                  onPressed: () {
                                    goTo(context, LoginScreen());
                                  }),
                            ],
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
