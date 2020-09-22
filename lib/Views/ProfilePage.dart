import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:image/image.dart' as Img;
import 'package:image_picker/image_picker.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Address.dart';
import 'package:male/Models/FirestoreImage.dart';
import 'package:male/Models/User.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Widgets/AddressesList.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:path/path.dart' as ppp;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'AddAddressPage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  ValueNotifier<bool> isUpdating = ValueNotifier<bool>(false);
  FirestoreImage profileImage = FirestoreImage();
  TextEditingController emailController = TextEditingController(text: '');
  TextEditingController passwordController = TextEditingController(text: '');
  TextEditingController nameController = TextEditingController(text: '');
  TextEditingController phoneController = TextEditingController(text: '');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var databaseUser = context.read<MainViewModel>().databaseUser.value;
    emailController.text = databaseUser.email;
    nameController.text = databaseUser.displayName;
    phoneController.text = databaseUser.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('Profile')),
      ),
      body: Consumer2<MainViewModel, User>(
        builder: (context, viewModel, firebaseUser, child) {
          return ValueListenableBuilder<DatabaseUser>(
            valueListenable: viewModel.databaseUser,
            builder: (context, databaseUser, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: isUpdating,
                builder: (context, value, child) => Stack(
                  children: [
                    child,
                    if (value)
                      Align(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                        ),
                      )
                  ],
                ),
                child: Container(
                    padding:
                        EdgeInsets.only(top: 0, left: 8, right: 8, bottom: 8),
                    child: databaseUser != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(
                                flex: 2,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FlatButton(
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(8),
                                        child: (profileImage
                                                        ?.downloadUrl?.length ??
                                                    0) >
                                                0
                                            ? Container(
                                                width: 100,
                                                height: 100,
                                                child: CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      profileImage.downloadUrl),
                                                ),
                                              )
                                            : (databaseUser?.photoUrl?.length ??
                                                        0) >
                                                    0
                                                ? Container(
                                                    width: 100,
                                                    height: 100,
                                                    child: CircleAvatar(
                                                      backgroundImage:
                                                          NetworkImage(
                                                              databaseUser
                                                                  .photoUrl),
                                                    ),
                                                  )
                                                : Icon(
                                                    FontAwesome.user,
                                                    color: Colors.grey.shade600,
                                                    size: 50,
                                                  ),
                                        onPressed: () async {
                                          try {
                                            var pickedImage =
                                                await ImagePicker().getImage(
                                                    source:
                                                        ImageSource.gallery);
                                            if (pickedImage != null) {
                                              File file =
                                                  File(pickedImage.path);
                                              Img.Image image_temp =
                                                  Img.decodeImage(
                                                      file.readAsBytesSync());
                                              Img.Image resized_img =
                                                  Img.copyResize(image_temp,
                                                      width: 800,
                                                      height: image_temp
                                                              .height ~/
                                                          (image_temp.width /
                                                              800));
                                              var data = Img.encodeJpg(
                                                  resized_img,
                                                  quality: 60);
                                              String filename =
                                                  '${Uuid().v4()}${ppp.basename(file.path)}';
                                              isUploading.value = true;
                                              var imgRef = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child('images')
                                                  .child(filename);
                                              var uploadTask =
                                                  imgRef.putData(data);
                                              profileImage.refPath =
                                                  imgRef.path;
                                              var res =
                                                  await uploadTask.onComplete;
                                              if (!uploadTask.isSuccessful)
                                                throw Exception(AppLocalizations
                                                        .of(context)
                                                    .translate(
                                                        'File upload failed'));
                                              String url = await res.ref
                                                  .getDownloadURL();
                                              String refPath = imgRef.path;
                                              if (!((url?.length ?? 0) > 0)) {
                                                throw Exception(AppLocalizations
                                                        .of(context)
                                                    .translate(
                                                        'File upload failed'));
                                              }
                                              setState(() {
                                                profileImage.downloadUrl = url;
                                              });
                                            }
                                          } on PlatformException catch (e) {
                                            try {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return OkDialog(
                                                        title: AppLocalizations
                                                                .of(context)
                                                            .translate('Error'),
                                                        content: e.message);
                                                  });
                                            } catch (e) {}
                                          } catch (e) {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return OkDialog(
                                                      title: AppLocalizations
                                                              .of(context)
                                                          .translate('Error'),
                                                      content: e.toString());
                                                });
                                          } finally {
                                            isUploading.value = false;
                                          }
                                        },
                                      ),
                                      if (viewModel.user != null) ...[
                                        Divider(
                                          height: 30,
                                        ),
                                        Text(
                                          firebaseUser == null
                                              ? AppLocalizations.of(context)
                                                  .translate('Unauthorized')
                                              : firebaseUser.isAnonymous
                                                  ? AppLocalizations.of(context)
                                                      .translate('Guest')
                                                  : (databaseUser.displayName
                                                                  ?.length ??
                                                              0) >
                                                          0
                                                      ? databaseUser
                                                              .displayName ??
                                                          ''
                                                      : databaseUser.email ??
                                                          '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.grey.shade700),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          height: 60,
                                          child: TextField(
                                            controller: emailController,
                                            decoration:
                                                kOutlineInputText.copyWith(
                                                    hintText: AppLocalizations
                                                            .of(context)
                                                        .translate(
                                                            'Email / Username')),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          height: 60,
                                          child: TextField(
                                            obscureText: true,
                                            controller: passwordController,
                                            keyboardType:
                                                TextInputType.visiblePassword,
                                            decoration:
                                                kOutlineInputText.copyWith(
                                                    hintText: AppLocalizations
                                                            .of(context)
                                                        .translate('Password')),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          height: 60,
                                          child: TextField(
                                            controller: nameController,
                                            decoration:
                                                kOutlineInputText.copyWith(
                                                    hintText:
                                                        AppLocalizations.of(
                                                                context)
                                                            .translate('Name')),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          height: 60,
                                          child: TextField(
                                            controller: phoneController,
                                            keyboardType: TextInputType.number,
                                            decoration:
                                                kOutlineInputText.copyWith(
                                                    hintText: AppLocalizations
                                                            .of(context)
                                                        .translate('Phone')),
                                          ),
                                        ),
                                        Divider(
                                          height: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .translate('Addresses'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('userAddresses')
                                            .where('uid',
                                                isEqualTo: databaseUser.uid)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.data != null) {
                                            return AddressesList(
                                              userAddresses: snapshot.data.docs
                                                  .map((e) =>
                                                      UserAddress.fromDocument(
                                                          e))
                                                  .toList(),
                                            );
                                          }
                                          return Container();
                                        },
                                      ),
                                      FlatButton(
                                        splashColor: kPrimary.withOpacity(0.2),
                                        highlightColor:
                                            kPrimary.withOpacity(.2),
                                        onPressed: () async {
                                          var userAddress =
                                              await Navigator.push<UserAddress>(
                                                  context,
                                                  MaterialPageRoute<
                                                      UserAddress>(
                                                    builder: (context) =>
                                                        AddAddressPage(),
                                                  ));
                                          if (userAddress != null) {
                                            FirebaseFirestore.instance
                                                .collection('/userAddresses')
                                                .doc()
                                                .set(userAddress.toJson());
                                          }
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .translate('Add address'),
                                          style: TextStyle(color: kPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(
                                height: 2,
                              ),
                              FlatButton(
                                onPressed: () async {
                                  try {
                                    setState(() {
                                      isUpdating.value = true;
                                    });

                                    Map<String, dynamic> updateData =
                                        Map<String, dynamic>();
                                    UserUpdateInfo uInfo;
                                    if ((profileImage?.downloadUrl?.length ??
                                            0) >
                                        0) {
                                      uInfo ??= UserUpdateInfo();
                                      uInfo.photoUrl = profileImage.downloadUrl;

                                      updateData['photoUrl'] =
                                          profileImage.downloadUrl;
                                      profileImage = null;
                                    }
                                    if ((emailController.text.length ?? 0) >
                                        0) {
                                      try {
                                        await firebaseUser
                                            .updateEmail(emailController.text);
                                        updateData['email'] =
                                            emailController.text;
                                      } on PlatformException catch (ee) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => OkDialog(
                                            title: AppLocalizations.of(context)
                                                .translate('Error'),
                                            content: ee.message,
                                          ),
                                        );
                                      }
                                    }
                                    if ((nameController.text.length ?? 0) > 0) {
                                      uInfo ??= UserUpdateInfo();
                                      uInfo.displayName = nameController.text;
                                      updateData['displayName'] =
                                          nameController.text;
                                    }
                                    if ((phoneController.text.length ?? 0) >
                                        0) {
                                      updateData['phoneNumber'] =
                                          phoneController.text;
                                    }
                                    if (updateData.length > 0) {
                                      await FirebaseFirestore.instance
                                          .collection('/users')
                                          .doc(databaseUser.uid)
                                          .update(updateData);
                                    }
                                    if ((passwordController.text.length ?? 0) >
                                        0) {
                                      await firebaseUser.updatePassword(
                                          passwordController.text);
                                    }
                                    if (uInfo != null) {
                                      await firebaseUser.updateProfile(
                                          displayName: uInfo.displayName,
                                          photoURL: uInfo.photoUrl);
                                      firebaseUser.reload();
                                    }
                                  } on PlatformException catch (ee) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => OkDialog(
                                        title: AppLocalizations.of(context)
                                            .translate('Error'),
                                        content: ee.message,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      isUpdating.value = false;
                                    });
                                  }
                                },
                                child: Text(AppLocalizations.of(context)
                                    .translate('Apply changes')),
                              )
                            ],
                          )
                        : Container(
                            child: Text('Unauthorized'),
                          )),
              );
            },
          );
        },
      ),
    );
  }
}

class UserUpdateInfo {
  String photoUrl;

  String displayName;
}
