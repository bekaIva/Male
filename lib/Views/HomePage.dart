import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_range_picker/date_range_picker.dart' as DateRagePicker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Category.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/LanguageSettings.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/ContactPage.dart';
import 'package:male/Views/OrdersPage.dart';
import 'package:male/Views/ProductPage.dart';
import 'package:male/Views/ProfilePage.dart';
import 'package:male/Views/SettingsPage.dart';
import 'package:male/Views/UsersPage.dart';
import 'package:male/Views/singup_loginPage.dart';
import 'package:male/Widgets/CategoryItemWidget.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

import 'CartPage.dart';
import 'CategoryPage.dart';

class HomePage extends StatefulWidget {
  static String id = 'HomePage';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> pages = [
    CategoryPage(),
    OrdersPage(),
    CartPage(),
  ];
  int pageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (_, mainvViewModel, child) {
        return Scaffold(
          bottomNavigationBar: pageIndex <= 2
              ? ValueListenableBuilder(
                  valueListenable: mainvViewModel.databaseUser,
                  builder: (context, value, child) {
                    return BottomNavigationBar(
                      unselectedItemColor: Colors.white54,
                      selectedItemColor: Colors.yellow,
                      backgroundColor: kPrimary,
                      currentIndex: pageIndex > 2 ? 0 : pageIndex,
                      onTap: (index) {
                        setState(() {
                          pageIndex = index;
                        });
                      },
                      items: [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.category),
                            label: AppLocalizations.of(context)
                                .translate('Categories')),
                        BottomNavigationBarItem(
                            icon: Icon(FontAwesome.list),
                            label: AppLocalizations.of(context)
                                .translate('Orders')),
                        BottomNavigationBarItem(
                            icon: ValueListenableBuilder(
                              valueListenable: mainvViewModel.cart,
                              builder: (context, value, child) {
                                return Container(
                                  width: double.infinity,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: <Widget>[
                                        mainvViewModel.cart.value.length > 0
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 30, bottom: 10),
                                                child: Material(
                                                  color: Colors.yellow,
                                                  elevation: 2,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: new Container(
                                                    padding: EdgeInsets.all(1),
                                                    decoration:
                                                        new BoxDecoration(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    constraints: BoxConstraints(
                                                      minWidth: 12,
                                                      minHeight: 12,
                                                    ),
                                                    child: new Text(
                                                      mainvViewModel
                                                          .cart.value.length
                                                          .toString(),
                                                      style: new TextStyle(
                                                          color: kPrimary,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : SizedBox(),
                                        Icon(Icons.shopping_cart),
                                      ]),
                                );
                              },
                            ),
                            label:
                                AppLocalizations.of(context).translate('Cart')),
                      ],
                    );
                  },
                )
              : null,
          appBar: () {
            switch (pageIndex) {
              case 0:
                {
                  return AppBar(
                    title: Text(
                        AppLocalizations.of(context).translate('Categories')),
                    actions: <Widget>[
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          showSearch(
                              context: context, delegate: CategorySearch());
                        },
                      )
                    ],
                  );
                }
              case 1:
                {
                  return AppBar(
                    title:
                        Text(AppLocalizations.of(context).translate('Orders')),
                    actions: [
                      IconButton(
                        onPressed: () async {
                          final List<DateTime> picked =
                              await DateRagePicker.showDatePicker(
                                  context: context,
                                  initialFirstDate: new DateTime.now(),
                                  initialLastDate: (new DateTime.now())
                                      .add(new Duration(days: 1)),
                                  firstDate: new DateTime(2015),
                                  lastDate: new DateTime(2021));
                          mainvViewModel.orderTimePicked?.call(picked);
                        },
                        icon: Icon(FontAwesome.filter),
                      )
                    ],
                  );
                }
              case 2:
                {
                  return AppBar(
                    title: Text(AppLocalizations.of(context).translate('Cart')),
                  );
                }
              default:
                {
                  return null;
                }
            }
          }(),
          drawer: Drawer(
            child: ValueListenableBuilder<DatabaseUser>(
              valueListenable: mainvViewModel.databaseUser,
              builder: (context, databaseUseruser, child) {
                return ListView(
                  children: <Widget>[
                    Consumer<User>(
                      builder: (context, user, child) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: mainvViewModel.isSigningSignUping,
                          builder: (context, value, child) {
                            return DrawerHeader(
                              decoration: BoxDecoration(color: kPrimary),
                              child: Stack(
                                children: <Widget>[
                                  Center(
                                    child: Text(
                                      user == null
                                          ? AppLocalizations.of(context)
                                              .translate('Unauthorized')
                                          : user.isAnonymous
                                              ? AppLocalizations.of(context)
                                                  .translate('Guest')
                                              : (databaseUseruser?.displayName
                                                              ?.length ??
                                                          0) >
                                                      0
                                                  ? databaseUseruser.displayName
                                                  : databaseUseruser?.email ??
                                                      '',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 22),
                                    ),
                                  ),
                                  if (value)
                                    Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    ),
                                  Consumer<LanguageSettings>(
                                    builder:
                                        (context, languageSettings, child) =>
                                            DropdownButton<Locale>(
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: kIcons,
                                      ),
                                      underline: Container(),
                                      onChanged: (val) {
                                        languageSettings.setLocale(val);
                                      },
                                      value:
                                          AppLocalizations.of(context).locale,
                                      items: AppLocalizations.supportedLocales
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e.countryCode
                                                    .toUpperCase()
                                                    .replaceAllMapped(
                                                        RegExp(r'[A-Z]'),
                                                        (match) => String
                                                            .fromCharCode(match
                                                                    .group(0)
                                                                    .codeUnitAt(
                                                                        0) +
                                                                127397))),
                                              ))
                                          .toList(),
                                      selectedItemBuilder: (context) =>
                                          AppLocalizations.supportedLocales
                                              .map((e) => Text(
                                                    e.countryCode
                                                        .toUpperCase()
                                                        .replaceAllMapped(
                                                            RegExp(r'[A-Z]'),
                                                            (match) => String
                                                                .fromCharCode(match
                                                                        .group(
                                                                            0)
                                                                        .codeUnitAt(
                                                                            0) +
                                                                    127397)),
                                                    style: TextStyle(
                                                        color: kIcons),
                                                  ))
                                              .toList(),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.home),
                      onTap: () {
                        setState(() {
                          pageIndex = 0;
                          Navigator.pop(context);
                        });
                      },
                      title:
                          Text(AppLocalizations.of(context).translate('Home')),
                    ),
                    if (databaseUseruser?.role == UserType.user)
                      ListTile(
                        leading: Icon(Icons.chat_bubble),
                        onTap: () {
                          setState(() {
                            mainvViewModel.newMessages.value = false;
                            FirebaseFirestore.instance
                                .collection('/newmessages')
                                .doc(
                                    'to${mainvViewModel.databaseUser.value.uid}FromAdmin')
                                .set({'hasNewMessages': false});

                            Navigator.pop(context);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ContactPage(),
                            ));
                          });
                        },
                        title: ValueListenableBuilder<bool>(
                          valueListenable: mainvViewModel.newMessages,
                          builder: (context, value, child) {
                            return Stack(
                              children: <Widget>[
                                Text(AppLocalizations.of(context)
                                    .translate('Contact us')),
                                if (value) child
                              ],
                            );
                          },
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: kPrimary, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                    if (databaseUseruser?.role == UserType.admin)
                      ListTile(
                        leading: Icon(FontAwesome.users),
                        onTap: () {
                          setState(() {
                            mainvViewModel.newMessages.value = false;

                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UsersPage(),
                                ));
                          });
                        },
                        title: ValueListenableBuilder<bool>(
                          valueListenable: mainvViewModel.adminNewMessages,
                          builder: (context, value, child) {
                            return Stack(
                              children: <Widget>[
                                Text(AppLocalizations.of(context)
                                    .translate('Users')),
                                if (value) child
                              ],
                            );
                          },
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: kPrimary, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                    if (databaseUseruser?.role == UserType.admin)
                      ListTile(
                        leading: Icon(Icons.settings),
                        onTap: () {
                          setState(() {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(),
                                ));
                          });
                        },
                        title: Text(
                            AppLocalizations.of(context).translate('Settings')),
                      ),
                    if (databaseUseruser != null)
                      ListTile(
                        leading: Icon(FontAwesome.user),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ));
                        },
                        title: Text(
                            AppLocalizations.of(context).translate('Profile')),
                      ),
                    Consumer<User>(
                      builder: (context, user, child) {
                        if (user == null) {
                          return ListTile(
                            leading: Icon(FontAwesome.sign_in),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SingUpLoginPage(
                                    login: true,
                                  ),
                                ),
                              );
                            },
                            title: Text(AppLocalizations.of(context)
                                .translate('Sign in')),
                          );
                        } else {
                          return ListTile(
                            leading: Icon(FontAwesome.sign_out),
                            onTap: () {
                              mainvViewModel.auth.signOut();
                            },
                            title: Text(AppLocalizations.of(context)
                                .translate('Sign out')),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          body: pages[pageIndex],
        );
      },
    );
  }
}

class CategorySearch extends SearchDelegate<String> {
  CategorySearch();
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) =>
          ValueListenableBuilder<List<Category>>(
        valueListenable: viewModel.categories,
        builder: (context, categories, child) =>
            ValueListenableBuilder<List<Product>>(
          valueListenable: viewModel.products,
          builder: (context, products, child) {
            final List<Category> suggestionList = query.isEmpty
                ? categories
                    .take(categories.length > 10 ? 10 : categories.length)
                    .toList()
                : categories
                    .where((element) => element.localizedName[
                            AppLocalizations.of(context).locale.languageCode]
                        .contains(query))
                    .toList();
            Map<Category, List<Product>> resultsMap = Map.fromIterable(
                suggestionList,
                key: (c) => c,
                value: (c) => null);

            var filteredProducts = (query?.length != 0)
                ? products?.where((element) => element.localizedName[
                        AppLocalizations.of(context).locale.languageCode]
                    .contains(query))
                : null;
            filteredProducts ??= [];
            filteredProducts.forEach((element) {
              var cat = categories.firstWhere(
                  (cat) => element.documentId == cat.documentId,
                  orElse: () => null);
              if (cat != null) {
                resultsMap[cat] ??= [];
                resultsMap[cat].add(element);
              }
            });
            try {
              resultsMap.values.forEach((element) {
                try {
                  element.sort((a, b) => (a?.order ?? 0) - (b?.order ?? 0));
                } catch (e) {}
              });
            } catch (e) {}
            return ValueListenableBuilder<DatabaseUser>(
              valueListenable: viewModel.databaseUser,
              builder: (context, user, child) {
                if (user.role == UserType.admin) {
                  return ListView.builder(
                    itemBuilder: (context, index) {
                      var c = resultsMap.keys.toList()[index];
                      return Column(
                        children: [
                          Slidable(
                            key: Key(c.localizedName[
                                AppLocalizations.supportedLocales.first]),
                            actionPane: SlidableDrawerActionPane(),
                            actions: <Widget>[
                              SlideAction(
                                onTap: () {
                                  var cat = Category.fromJson(c.toJson());
                                  showModalBottomSheet(
                                      context: context,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (context) {
                                        return EditCategoryWidget(
                                          category: cat,
                                          onEditClicked: (newC) {
                                            viewModel.updateCategory(c, newC);
                                          },
                                        );
                                      });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SlideActionElement(
                                    iconData: Icons.edit,
                                    color: Colors.blue,
                                    text: AppLocalizations.of(context)
                                        .translate('Edit'),
                                  ),
                                ),
                              ),
                            ],
                            secondaryActions: <Widget>[
                              SlideAction(
                                onTap: () {
                                  viewModel.deleteCategory(c);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SlideActionElement(
                                    iconData: Icons.delete,
                                    text: AppLocalizations.of(context)
                                        .translate('Delete'),
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                            child: CategoryWidget(
                              onCategoryPress: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ProductPage(
                                          category: c,
                                        )));
                              },
                              category: c,
                            ),
                          ),
                          if ((resultsMap[c]?.length ?? 0) > 0)
                            ...?resultsMap[c].map((e) => Container(
                                  padding: EdgeInsets.only(
                                      left: 30, right: 8, top: 4, bottom: 4),
                                  child: Slidable(
                                    key: Key(e.productDocumentId),
                                    actionPane: SlidableDrawerActionPane(),
                                    actions: <Widget>[
                                      SlideAction(
                                        onTap: () {
                                          showBottomSheet(
                                              context: context,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                ),
                                              ),
                                              builder: (c) {
                                                return AddProductWidget(
                                                  onAddClicked: (p) {
                                                    viewModel
                                                        .storeProduct(p)
                                                        .catchError((error) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            OkDialog(
                                                          title: AppLocalizations
                                                                  .of(context)
                                                              .translate(
                                                                  'Error'),
                                                          content:
                                                              error.toString(),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                  pc: e,

//
                                                );
                                              });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(15.0))),
                                            child: Material(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(15))),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              15.0)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFFABABAB)
                                                          .withOpacity(0.7),
                                                      blurRadius: 4.0,
                                                      spreadRadius: 3.0,
                                                    ),
                                                  ],
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                15.0)),
                                                    color: Colors.black12
                                                        .withOpacity(0.1),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Icon(
                                                              Icons.edit,
                                                              color: kIcons,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                      context)
                                                                  .translate(
                                                                      'Edit'),
                                                              style: TextStyle(
                                                                  color:
                                                                      kIcons),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  height: double.infinity,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    secondaryActions: <Widget>[
                                      SlideAction(
                                        onTap: () {
                                          viewModel.deleteProduct(e);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(15.0))),
                                            child: Material(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(15))),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              15.0)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFFABABAB)
                                                          .withOpacity(0.7),
                                                      blurRadius: 4.0,
                                                      spreadRadius: 3.0,
                                                    ),
                                                  ],
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                15.0)),
                                                    color: Colors.black12
                                                        .withOpacity(0.1),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Icon(
                                                              Icons.delete,
                                                              color: kIcons,
                                                            ),
                                                            Text(
                                                              AppLocalizations.of(
                                                                      context)
                                                                  .translate(
                                                                      'Delete'),
                                                              style: TextStyle(
                                                                  color:
                                                                      kIcons),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  height: double.infinity,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ProductItem(
                                        p: e,
                                      ),
                                    ),
                                  ),
                                )),
                        ],
                      );
                    },
                    itemCount: resultsMap.keys.length,
                  );
                } else {
                  return ListView.builder(
                    itemCount: resultsMap.keys.length,
                    itemBuilder: (context, index) {
                      var c = resultsMap.keys.toList()[index];
                      return Column(
                        children: [
                          CategoryWidget(
                            category: c,
                            onCategoryPress: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) {
                                return ProductPage(
                                  category: c,
                                );
                              }));
                            },
                          ),
                          if ((resultsMap[c]?.length ?? 0) > 0)
                            ...?resultsMap[c].map((e) => Container(
                                  padding: EdgeInsets.only(
                                      left: 30, right: 8, top: 4, bottom: 4),
                                  child: ProductItem(
                                    cartControl: user.role == UserType.user
                                        ? CartControl(
                                            product: e,
                                          )
                                        : null,
                                    p: e,
                                  ),
                                )),
                        ],
                      );
                    },
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
