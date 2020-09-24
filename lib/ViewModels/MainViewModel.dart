import 'dart:async';

import 'package:audioplayers/audio_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:male/Models/CartItem.dart';
import 'package:male/Models/Category.dart';
import 'package:male/Models/ChatMessage.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/Settings.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainViewModel extends ChangeNotifier {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  int lastOrderId;
  User user;
  final auth = FirebaseAuth.instance;
  // AuthResult authResult;
  SharedPreferences prefs;
  bool isConnected = false;
  ValueNotifier<bool> isSigningSignUping = ValueNotifier<bool>(false);
  ValueNotifier<DatabaseUser> databaseUser = ValueNotifier<DatabaseUser>(null);
  ValueNotifier<List<Category>> categories = ValueNotifier<List<Category>>([]);
  ValueNotifier<List<CartItem>> cart = ValueNotifier<List<CartItem>>([]);
  ValueNotifier<bool> newMessages = ValueNotifier<bool>(false);
  ValueNotifier<bool> adminNewMessages = ValueNotifier<bool>(false);
  ValueNotifier<List<ChatMessage>> userMessages =
      ValueNotifier<List<ChatMessage>>([]);
  ValueNotifier<AppSettings> settings =
      ValueNotifier<AppSettings>(AppSettings());
  ValueNotifier<List<DatabaseUser>> users =
      ValueNotifier<List<DatabaseUser>>([]);
  MainViewModel() {
    init();
  }
  void signAnonymouslyifNotSigned() async {
    try {
      isSigningSignUping.value = true;
      if (auth.currentUser == null) {
        var res = await auth.signInAnonymously();
        if (res != null) {
          await storeNewUser(res.user, UserType.user);
        }
      }
    } catch (e) {
      print(e);
    } finally {
      isSigningSignUping.value = false;
    }
  }

  Future<bool> signInWithEmailAndPassword() async {
    try {
      isSigningSignUping.value = true;
      var authRes = await auth.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
      if (authRes != null) {
        return true;
      } else
        return false;
    } catch (e) {
      throw e;
    } finally {
      isSigningSignUping.value = false;
    }
  }

  Future signUpWithEmailAndPassword() async {
    try {
      isSigningSignUping.value = true;
      var authRes = await auth.createUserWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);
      if (authRes != null) {
        await storeNewUser(authRes.user, UserType.user);
        return true;
      } else
        return false;
    } catch (e) {
      throw e;
    } finally {
      isSigningSignUping.value = false;
    }
  }

  StreamSubscription<QuerySnapshot> databaseUserListener;
  StreamSubscription<QuerySnapshot> cartListener;
  StreamSubscription<QuerySnapshot> categoryListener;
  StreamSubscription<QuerySnapshot> productListener;
  StreamSubscription<QuerySnapshot> chatListener;
  StreamSubscription<QuerySnapshot> usersListener;
  List<StreamSubscription<QuerySnapshot>> usersMessagesListener;
  List<StreamSubscription<DocumentSnapshot>> usersNewMessagesListener;
  StreamSubscription<DocumentSnapshot> newMessagesListener;
  StreamSubscription<DocumentSnapshot> settingsListener;
  StreamSubscription<DocumentSnapshot> ordersCounterListener;

  Future init() async {
    auth.authStateChanges().listen((event) {
      if (event != null) {
        user = event;

        cartListener?.cancel();
        cartListener = FirebaseFirestore.instance
            .collection('/cart')
            .where('userId', isEqualTo: user.uid)
            .snapshots()
            .listen((event) {
          try {
            List<CartItem> c = [];
            event.docs.forEach((element) {
              CartItem ci = CartItem.fromJson(element.data());
              ci.documentId = element.id;
              c.add(ci);
            });
            cart.value = c;
          } catch (e) {}
        });

        categoryListener?.cancel();
        categoryListener = FirebaseFirestore.instance
            .collection('/categories')
            .orderBy('order')
            .snapshots()
            .listen((event) {
          List<Category> cs = [];
          event.docs.forEach((element) {
            var c = Category.fromJson(element.data());
            c.documentId = element.id;
            cs.add(c);
          });
          categories.value = cs;
        });

        productListener?.cancel();
        categoryListener = FirebaseFirestore.instance
            .collection('/categories')
            .orderBy('order')
            .snapshots()
            .listen((event) {
          List<Category> cs = [];
          event.docs.forEach((element) {
            var c = Category.fromJson(element.data());
            c.documentId = element.id;
            cs.add(c);
          });
          categories.value = cs;
        });
        databaseUserListener?.cancel();
        databaseUserListener = FirebaseFirestore.instance
            .collection('/users')
            .where('uid', isEqualTo: user?.uid ?? '')
            .snapshots()
            .listen((event) {
          try {
            databaseUser.value = DatabaseUser.fromMap(event.docs
                .firstWhere((element) => element.id == user.uid)
                .data());

            usersListener?.cancel();
            chatListener?.cancel();
            usersNewMessagesListener?.forEach((element) {
              element?.cancel();
            });
            usersMessagesListener?.forEach((element) {
              element?.cancel();
            });

            newMessagesListener?.cancel();
            switch (databaseUser.value.role) {
              case UserType.user:
                {
                  newMessagesListener = FirebaseFirestore.instance
                      .collection('/newmessages')
                      .doc('to${databaseUser.value.uid}FromAdmin')
                      .snapshots()
                      .listen((event) {
                    if (event.data != null) {
                      try {
                        newMessages.value =
                            event.data()['hasNewMessages'] as bool;
                        if (newMessages.value) AudioCache().play('stairs.mp3');
                      } catch (e) {}
                    }
                  });
                  chatListener = FirebaseFirestore.instance
                      .collection('/messages')
                      .where(
                        'pair',
                        isEqualTo: 'admin${databaseUser.value.uid}',
                      )
                      .orderBy('serverTime', descending: false)
                      .snapshots()
                      .listen((event) {
                    userMessages.value = event.docs
                        .map((e) => ChatMessage.fromJson(e.data()))
                        .toList();
                  });
                  break;
                }
              case UserType.admin:
                {
                  usersListener = FirebaseFirestore.instance
                      .collection('/users')
                      .snapshots()
                      .listen((event) {
                    users.value = event.docs
                        .map((e) => DatabaseUser.fromMap(e.data()))
                        .toList();

                    usersNewMessagesListener = users.value.map((e) {
                      return FirebaseFirestore.instance
                          .collection('/newmessages')
                          .doc('toAdminFrom${e.uid}')
                          .snapshots()
                          .listen((event) {
                        if (event.data != null) {
                          try {
                            e.hasNewMessages.value =
                                event.data()['hasNewMessages'] as bool;
                            adminNewMessages.value = users.value
                                .any((element) => element.hasNewMessages.value);

                            if (adminNewMessages.value)
                              AudioCache().play('stairs.mp3');
                          } catch (e) {}
                        }
                      });
                    }).toList();

                    usersMessagesListener = users.value.map((e) {
                      return FirebaseFirestore.instance
                          .collection('/messages')
                          .where(
                            'pair',
                            isEqualTo: 'admin${e.uid}',
                          )
                          .orderBy('serverTime', descending: false)
                          .snapshots()
                          .listen((event) {
                        e.messages.value = event.docs
                            .map((e) => ChatMessage.fromJson(e.data()))
                            .toList();
                      });
                    }).toList();
                  });
                  break;
                }
            }
          } catch (e) {}
        });
      } else {
        databaseUser.value = null;
      }
    });

    ordersCounterListener?.cancel();
    ordersCounterListener = FirebaseFirestore.instance
        .collection('/settings')
        .doc('ordersCounterDocument')
        .snapshots()
        .listen((event) {
      try {
        if (event?.data != null) {
          lastOrderId = event.data()['ordersCounterField'] as int;
          print(lastOrderId);
        } else {
          lastOrderId = null;
        }
      } catch (e) {}
    });
    settingsListener?.cancel();
    settingsListener = FirebaseFirestore.instance
        .collection('/settings')
        .doc('settings')
        .snapshots()
        .listen((event) {
      try {
        if (event.data != null) {
          settings.value = AppSettings.fromJson(event.data());
        }
      } catch (e) {
        print(e);
      }
    });
    signAnonymouslyifNotSigned();
    prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'ServerBaseAddress', 'http://bsoftstudio-001-site2.etempurl.com/');
    /*prefs.setString('ServerBaseAddress', 'http://192.168.100.11:44379/');*/
    prefs.setString('CheckoutBackLink',
        '${prefs.getString('ServerBaseAddress')}CheckoutResult');
  }

  Future<DocumentReference> storeCategory(Category c) async {
    c.order = categories.value.length > 0 ? categories.value.last.order + 1 : 1;

    return FirebaseFirestore.instance.collection('/categories').doc()
      ..set(
          c.toJson(),
          SetOptions(
            merge: true,
          ));
  }

  Future storeProduct(
    Product p,
  ) async {
    await FirebaseFirestore.instance
        .collection('productsCounter')
        .doc('counter')
        .set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
    await FirebaseFirestore.instance
        .collection('/products')
        .doc(p.productDocumentId)
        .set(
            p.toJson(),
            SetOptions(
              merge: true,
            ));
  }

  Future storeCart(Product p) async {
    if (user == null) throw Exception('Unauthorized');
    CartItem c = CartItem(userId: user.uid, product: p);
    await FirebaseFirestore.instance.collection('cart').doc().set(
          c.toJson(),
        );
  }

  Future switchCategoriesOrders(Category first, Category second) async {
    FirebaseFirestore.instance
        .collection('/categories')
        .doc(first.documentId)
        .update({'order': second.order});
    FirebaseFirestore.instance
        .collection('/categories')
        .doc(second.documentId)
        .update({'order': first.order});
  }

  Future updateCategory(Category oldCat, Category newCat) async {
    var js = newCat.toJson();
    FirebaseFirestore.instance
        .collection('/categories')
        .doc(oldCat.documentId)
        .update(newCat.toJson());
  }

  Future storeNewUser(User user, UserType role) async {
    var u = DatabaseUser.fromFirebaseUser(user, role);
    await FirebaseFirestore.instance
        .collection('/users')
        .doc(user.uid)
        .set(u.toMap(), SetOptions(merge: true));
  }

  Future deleteCategory(Category c) {
    FirebaseFirestore.instance
        .collection('/categories')
        .doc(c.documentId)
        .delete();
    FirebaseFirestore.instance
        .collection('/products')
        .where('documentId', isEqualTo: c.documentId)
        .get()
        .then((value) => value.docs.forEach((element) {
              var p = Product.fromJson(element.data());
              p.images.forEach((element) {
                FirebaseStorage.instance.ref().child(element.refPath).delete();
              });

              element.reference.delete();
            }));
    FirebaseStorage.instance.ref().child(c.image.refPath).delete();
  }

  Future deleteProduct(Product product) {
    FirebaseFirestore.instance
        .collection('/products')
        .doc(product.productDocumentId)
        .delete();
    product.images.forEach((element) {
      FirebaseStorage.instance.ref().child(element.refPath).delete();
    });
  }
}
