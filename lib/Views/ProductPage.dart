import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as Img;
import 'package:image_picker/image_picker.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/CartItem.dart';
import 'package:male/Models/Category.dart';
import 'package:male/Models/FirestoreImage.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/ProductDetailPage.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:path/path.dart' as ppp;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'CartPage.dart';

class ProductPage extends StatefulWidget {
  final Category category;
  static String id = 'ProductPage';
  ProductPage({this.category});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void didUpdateWidget(ProductPage oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (BuildContext context, MainViewModel viewModel, Widget child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.category.localizedName[
                    AppLocalizations.of(context).locale.languageCode] ??
                widget.category
                    .localizedName[AppLocalizations.supportedLocales.first] ??
                ''),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                      context: context,
                      delegate: ProductsSearch(
                          products: viewModel.products.value
                              .where((element) =>
                                  element.documentId ==
                                  widget.category.documentId)
                              .toList()));
                },
              ),
              ValueListenableBuilder<List<CartItem>>(
                valueListenable: viewModel.cart,
                builder: (context, cart, child) {
                  return Padding(
                    padding: EdgeInsets.only(top: 4, right: 2),
                    child: Stack(
                      children: [
                        child,
                        if ((cart?.length ?? 0) > 0)
                          Positioned.fill(
                              child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 3, top: 3),
                                    child: Material(
                                      color: Colors.yellow,
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(6),
                                      child: new Container(
                                        padding: EdgeInsets.all(1),
                                        decoration: new BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 12,
                                          minHeight: 12,
                                        ),
                                        child: new Text(
                                          viewModel.cart.value.length
                                              .toString(),
                                          style: new TextStyle(
                                              color: kPrimary,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  )))
                      ],
                    ),
                  );
                },
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return Scaffold(
                            appBar: AppBar(
                              title: Text(AppLocalizations.of(context)
                                  .translate('Cart')),
                            ),
                            body: CartPage(),
                          );
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.shopping_cart),
                ),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              return SafeArea(
                child: ValueListenableBuilder<DatabaseUser>(
                  builder: (BuildContext context, user, Widget child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<ConnectionState>(
                            valueListenable: viewModel.productConnectionState,
                            builder: (context, connectionState, child) {
                              if (connectionState == ConnectionState.waiting)
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation(kPrimary),
                                  ),
                                );
                              return child;
                            },
                            child: ValueListenableBuilder<List<Product>>(
                              valueListenable: viewModel.products,
                              builder: (context, val, child) {
                                List<Product> products = val
                                    .where((element) =>
                                        element.documentId ==
                                        widget.category.documentId)
                                    .toList();
                                if (products.length == 0)
                                  return Stack(
                                    children: [
                                      Container(
                                          constraints: BoxConstraints.expand(),
                                          child: SvgPicture.asset(
                                              'assets/svg/NoItem.svg')),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                4),
                                        child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Text(
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'You have nothing here'),
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: kPrimary,
                                                  shadows: [
                                                    BoxShadow(
                                                        color: Colors.white
                                                            .withOpacity(1),
                                                        blurRadius: 10.0,
                                                        spreadRadius: 2.0)
                                                  ]),
                                            )),
                                      )
                                    ],
                                  );
                                try {
                                  try {
                                    if (user.role == UserType.user) {
                                      products = products
                                          .where((element) =>
                                              element.quantityInSupply != 0)
                                          .toList();
                                    }
                                  } catch (e) {
                                    print(e.toString());
                                  }
                                  products.sort((a, b) =>
                                      (a?.order ?? 0) - (b?.order ?? 0));
                                } catch (e) {}

                                return user?.role == UserType.admin
                                    ? ListView.builder(
                                        itemBuilder: (context, index) {
                                          return Slidable(
                                            key: Key(products[index]
                                                .productDocumentId),
                                            actionPane:
                                                SlidableDrawerActionPane(),
                                            actions: <Widget>[
                                              SlideAction(
                                                onTap: () {
                                                  showBottomSheet(
                                                      context: context,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  20),
                                                          topRight:
                                                              Radius.circular(
                                                                  20),
                                                        ),
                                                      ),
                                                      builder: (c) {
                                                        return AddProductWidget(
                                                          onAddClicked: (p) {
                                                            viewModel
                                                                .storeProduct(p)
                                                                .catchError(
                                                                    (error) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        OkDialog(
                                                                  title: AppLocalizations.of(
                                                                          context)
                                                                      .translate(
                                                                          'Error'),
                                                                  content: error
                                                                      .toString(),
                                                                ),
                                                              );
                                                            });
                                                          },
                                                          pc: products[index],

//
                                                        );
                                                      });
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    15.0))),
                                                    child: Material(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          15))),
                                                      child: DecoratedBox(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.blue,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          15.0)),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Color(
                                                                      0xFFABABAB)
                                                                  .withOpacity(
                                                                      0.7),
                                                              blurRadius: 4.0,
                                                              spreadRadius: 3.0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius.circular(
                                                                        15.0)),
                                                            color: Colors
                                                                .black12
                                                                .withOpacity(
                                                                    0.1),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Container(
                                                              child: Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: <
                                                                      Widget>[
                                                                    Icon(
                                                                      Icons
                                                                          .edit,
                                                                      color:
                                                                          kIcons,
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
                                                          height:
                                                              double.infinity,
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
                                                  viewModel.deleteProduct(
                                                      products[index]);
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    15.0))),
                                                    child: Material(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          15))),
                                                      child: DecoratedBox(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          15.0)),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Color(
                                                                      0xFFABABAB)
                                                                  .withOpacity(
                                                                      0.7),
                                                              blurRadius: 4.0,
                                                              spreadRadius: 3.0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius.circular(
                                                                        15.0)),
                                                            color: Colors
                                                                .black12
                                                                .withOpacity(
                                                                    0.1),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Container(
                                                              child: Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: <
                                                                      Widget>[
                                                                    Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color:
                                                                          kIcons,
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
                                                          height:
                                                              double.infinity,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: ProductItem(
                                                p: products[index],
                                                onDownPress: products.last !=
                                                        products[index]
                                                    ? () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'products')
                                                            .doc(products[index]
                                                                .productDocumentId)
                                                            .update({
                                                          'order': products[
                                                                  index + 1]
                                                              .order
                                                        });
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'products')
                                                            .doc(products[
                                                                    index + 1]
                                                                .productDocumentId)
                                                            .update({
                                                          'order':
                                                              products[index]
                                                                  .order
                                                        });
                                                      }
                                                    : null,
                                                onUpPress: products.first !=
                                                        products[index]
                                                    ? () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'products')
                                                            .doc(products[index]
                                                                .productDocumentId)
                                                            .update({
                                                          'order': products[
                                                                  index - 1]
                                                              .order
                                                        });
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'products')
                                                            .doc(products[
                                                                    index - 1]
                                                                .productDocumentId)
                                                            .update({
                                                          'order':
                                                              products[index]
                                                                  .order
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        itemCount: products.length,
                                      )
                                    : ListView(
                                        children: <Widget>[
                                          ...products.map(
                                            (e) => Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: ProductItem(
                                                p: e,
                                                cartControl:
                                                    user?.role == UserType.user
                                                        ? CartControl(
                                                            product: e,
                                                          )
                                                        : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                              },
                            ),
                          ),
                        ),
                        if (user?.role == UserType.admin) child,
                      ],
                    );
                  },
                  valueListenable: viewModel.databaseUser,
                  child: FlatButton(
                    color: kPrimary,
                    onPressed: () {
                      showBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          builder: (context) {
                            return AddProductWidget(
                              pc: Product(
                                  localizedDescription: {},
                                  localizedName: {},
                                  addonDescriptions: [],
                                  checkableAddons: [],
                                  selectableAddons: [],
                                  images: []),
                              onAddClicked: (p) async {
                                p.documentId = widget.category.documentId;
                                try {
                                  viewModel.storeProduct(p).catchError((error) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => OkDialog(
                                        title: AppLocalizations.of(context)
                                            .translate('Error'),
                                        content: error.toString(),
                                      ),
                                    );
                                  });
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => OkDialog(
                                      title: AppLocalizations.of(context)
                                          .translate('Error'),
                                      content: e.toString(),
                                    ),
                                  );
                                }
                              },
                            );
                          });
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('Add Product'),
                      style: TextStyle(color: kIcons),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProductItem extends StatefulWidget {
  final CartControl cartControl;
  final Function onUpPress;
  final Function onDownPress;
  const ProductItem(
      {@required this.p, this.onDownPress, this.onUpPress, this.cartControl});

  final Product p;

  @override
  _ProductItemState createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return Material(
          borderRadius: BorderRadius.circular(4),
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(
                      p: widget.p,
                    ),
                  )).whenComplete(() {
                setState(() {});
              });
            },
            child: Container(
              margin: EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.2),
                    blurRadius: 3.5,
                    spreadRadius: 0.4,
                  )
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Hero(
                              tag: 'headerImage${widget.p.productDocumentId}',
                              child: Container(
                                height: 140,
                                width: 160,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: safeNetworkImage(widget.p?.images
                                          ?.firstWhere((element) => true,
                                              orElse: () => null)
                                          ?.downloadUrl),
                                    )),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(left: 12, top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      widget.p.localizedName[
                                              AppLocalizations.of(context)
                                                  .locale
                                                  .languageCode] ??
                                          '',
                                      style: TextStyle(
                                          fontFamily: "Sans",
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    ...?widget.p.addonDescriptions
                                        ?.map((e) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${e.localizedAddonDescriptionName[AppLocalizations.of(context).locale.languageCode] ?? ''}',
                                                    style: kContentStyle,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    '${e.localizedAddonDescription[AppLocalizations.of(context).locale.languageCode] ?? ''}',
                                                    style: kContentStyle,
                                                  ),
                                                ),
                                                Divider(
                                                  height: 2,
                                                ),
                                              ],
                                            )),
                                    if (widget.p.quantityInSupply != null)
                                      Row(
                                        children: [
                                          Text(
                                            '${AppLocalizations.of(context).translate('Quantity in supply')}: ',
                                            style: kContentStyle,
                                          ),
                                          Text(
                                            widget.p.quantityInSupply
                                                .toString(),
                                            style: kContentStyle,
                                          ),
                                        ],
                                      ),
                                    if (widget.p?.checkableAddons?.firstWhere(
                                            (element) => element.isSelected,
                                            orElse: () => null) !=
                                        null)
                                      Row(
                                        children: [
                                          Text(
                                            '${widget.p.checkableAddons.firstWhere((element) => element.isSelected, orElse: () => null).localizedName[AppLocalizations.of(context).locale.languageCode] ?? ''} ',
                                            style: kContentStyle,
                                          ),
                                          Text(
                                            () {
                                              var p = widget.p.checkableAddons
                                                  .firstWhere(
                                                      (element) =>
                                                          element.isSelected,
                                                      orElse: () => null);
                                              if (p?.price != null)
                                                return '+${p.price.toString()}₾';
                                              else
                                                return '';
                                            }(),
                                            // '${widget.p.checkableAddons.firstWhere((element) => element.isSelected, orElse: () => null)?.price ?? ''}₾',
                                            style: kSmallHeader,
                                          ),
                                        ],
                                      ),
                                    if ((widget?.p?.selectableAddons
                                                ?.where((element) =>
                                                    element.isSelected)
                                                ?.length ??
                                            0) >
                                        0)
                                      Column(
                                        children: [
                                          SizedBox(
                                            height: 2,
                                          ),
                                          Text(
                                            AppLocalizations.of(context)
                                                .translate('Addons'),
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          ...?widget?.p?.selectableAddons
                                              ?.where((element) =>
                                                  element.isSelected)
                                              ?.map(
                                                (e) => Row(
                                                  children: [
                                                    Flexible(
                                                      fit: FlexFit.tight,
                                                      child: Text(
                                                        '${e.localizedName[AppLocalizations.of(context).locale.languageCode] ?? ''} ',
                                                        style: TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    ),
                                                    if (e.price != null)
                                                      Text(
                                                        '${e.price ?? 0}₾',
                                                        style: TextStyle(
                                                          fontFamily: 'Sans',
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    SizedBox(
                                                      width: 2,
                                                    )
                                                  ],
                                                ),
                                              ),
                                        ],
                                      ),
                                  ],
                                ),
//
                              ),
                            ),
                          ],
                        ),
                        if ((widget
                                    .p
                                    .localizedDescription[
                                        AppLocalizations.of(context)
                                            .locale
                                            .languageCode]
                                    ?.length ??
                                0) >
                            0)
                          Column(
                            children: [
                              Divider(),
                              Text(
                                widget.p.localizedDescription[
                                        AppLocalizations.of(context)
                                            .locale
                                            .languageCode] ??
                                    '',
                                maxLines: null,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        Text(
                          '₾${widget.p?.totalProductPrice?.toString()}',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: kPrimary, fontFamily: 'Sans'),
                        ),
                        if (widget.cartControl != null &&
                            ((widget.p.quantityInSupply ?? 0) > 0 ||
                                widget.p.quantityInSupply == null))
                          widget.cartControl,
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (widget.onUpPress != null)
                          Align(
                            alignment: Alignment.topRight,
                            child: RawMaterialButton(
                              onPressed: widget.onUpPress,
                              splashColor: kPrimary.withOpacity(0.3),
                              shape: CircleBorder(),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ),
                        if (widget.onDownPress != null)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: RawMaterialButton(
                              onPressed: widget.onDownPress,
                              splashColor: kPrimary.withOpacity(0.3),
                              shape: CircleBorder(),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddProductWidget extends StatefulWidget {
  final Function(Product) onAddClicked;
  AddProductWidget({this.onAddClicked, this.pc});
  final Product pc;
  @override
  _AddProductWidgetState createState() => _AddProductWidgetState();
}

class _AddProductWidgetState extends State<AddProductWidget> {
  String selectedLocal = AppLocalizations.supportedLocales.first.languageCode;
  ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  bool addClicked = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    localeSelected();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    localeSelected();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
//
  }

  void localeSelected() {
    setTextControllers();
  }

  void setTextControllers() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      height: double.infinity,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ...AppLocalizations.supportedLocales.map((e) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            shape: CircleBorder(),
                            elevation: 4,
                            child: AnimatedContainer(
                              padding: EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: e.languageCode == selectedLocal
                                    ? kPrimary
                                    : kIcons,
                              ),
                              duration: Duration(milliseconds: 200),
                              child: RawMaterialButton(
                                constraints:
                                    BoxConstraints(minWidth: 50, minHeight: 50),
                                shape: CircleBorder(),
                                onPressed: () {
                                  setState(() {
                                    selectedLocal = e.languageCode;
                                    localeSelected();
                                  });
                                },
                                padding: EdgeInsets.all(0),
                                child: Text(
                                  e.languageCode,
                                  style: TextStyle(
                                    color: e.languageCode == selectedLocal
                                        ? kIcons
                                        : kPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              TextField(
                controller: TextEditingController()
                  ..text = widget.pc.localizedName[selectedLocal] ?? '',
                onChanged: (value) {
                  widget.pc.localizedName ??= {};
                  widget.pc.localizedName[selectedLocal] = value;
                },
                style: TextStyle(),
                cursorColor: kPrimary,
                decoration: InputDecoration(
                    suffixText: selectedLocal,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    hintStyle: TextStyle(),
                    hintText:
                        AppLocalizations.of(context).translate("Product Name")),
              ),
              TextField(
                controller: TextEditingController(
                    text: widget.pc.localizedDescription[selectedLocal] ?? ''),
                maxLines: null,
                onChanged: (value) {
                  widget.pc.localizedDescription ??= {};
                  widget.pc.localizedDescription[selectedLocal] = value;
                },
                style: TextStyle(),
                cursorColor: kPrimary,
                decoration: InputDecoration(
                    suffixText: selectedLocal,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    hintStyle: TextStyle(),
                    hintText: AppLocalizations.of(context)
                        .translate("Product Description")),
              ),
              TextField(
                controller: TextEditingController(
                    text: widget.pc.basePrice?.toString() ?? ''),
                decoration: kinputFiledDecoration.copyWith(
                    hintText:
                        AppLocalizations.of(context).translate('Base price')),
                onChanged: (val) {
                  widget.pc.basePrice = double.parse(val);
                },
              ),
              TextField(
                controller: TextEditingController(
                    text: widget.pc.quantityInSupply?.toString() ?? ''),
                decoration: kinputFiledDecoration.copyWith(
                    hintText: AppLocalizations.of(context)
                        .translate('Quantity in supply')),
                onChanged: (val) {
                  widget.pc.quantityInSupply =
                      int.parse(val, onError: (val) => null);
                },
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                AppLocalizations.of(context)
                    .translate('Additional descriptions'),
                textAlign: TextAlign.center,
              ),
              ...?widget.pc.addonDescriptions
                  ?.map((e) => Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 12,
                              ),
                              Text(
                                  '#${widget.pc.addonDescriptions.indexOf(e).toString()}'),
                              Flexible(
                                fit: FlexFit.loose,
                                child: TextField(
                                  controller: TextEditingController(
                                      text: e.localizedAddonDescriptionName[
                                          selectedLocal]),
                                  onChanged: (val) {
                                    e.localizedAddonDescriptionName[
                                        selectedLocal] = val;
                                  },
                                  decoration: kinputFiledDecoration.copyWith(
                                      suffixText: selectedLocal,
                                      hintText: AppLocalizations.of(context)
                                          .translate('Description name')),
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: TextField(
                                  controller: TextEditingController(
                                      text: e.localizedAddonDescription[
                                          selectedLocal]),
                                  maxLines: null,
                                  onChanged: (val) {
                                    e.localizedAddonDescription[selectedLocal] =
                                        val;
                                  },
                                  decoration: kinputFiledDecoration.copyWith(
                                      suffixText: selectedLocal,
                                      hintText: AppLocalizations.of(context)
                                          .translate('Description')),
                                ),
                              ),
                              Divider(),
                            ],
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  setState(() {
                                    widget.pc.addonDescriptions.remove(e);
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 22,
                                  color: Colors.red.withOpacity(.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ))
                  ?.toList(),
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      widget.pc.addonDescriptions.add(AddonDescription(
                          localizedAddonDescription: {},
                          localizedAddonDescriptionName: {}));
                    });
                  },
                  child: Icon(Icons.add),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                AppLocalizations.of(context)
                    .translate('Selectable paid addons'),
                textAlign: TextAlign.center,
              ),
              ...?widget.pc.checkableAddons
                  ?.map((e) => Row(
                        children: [
                          Radio(
                            activeColor: kPrimary,
                            value: e,
                            groupValue: widget?.pc?.checkableAddons?.firstWhere(
                                (element) => element.isSelected,
                                orElse: () => null),
                            onChanged: (val) {
                              setState(() {
                                widget.pc.checkableAddons.forEach((element) {
                                  element.isSelected = false;
                                });
                                (val as PaidAddon).isSelected = true;
                              });
                            },
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    TextField(
                                      controller: TextEditingController(
                                          text: e.localizedName[selectedLocal]),
                                      onChanged: (val) {
                                        e.localizedName[selectedLocal] = val;
                                      },
                                      decoration:
                                          kinputFiledDecoration.copyWith(
                                              suffixText: selectedLocal,
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('Addon name')),
                                    ),
                                    TextField(
                                      controller: TextEditingController(
                                          text: e.price?.toString() ?? ''),
                                      decoration:
                                          kinputFiledDecoration.copyWith(
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('Price')),
                                      onChanged: (val) {
                                        e.price =
                                            double.parse(val, (s) => null);
                                      },
                                    ),
                                    Divider(
                                      height: 30,
                                    )
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      splashColor: kPrimary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () async {
                                        setState(() {
                                          widget.pc.checkableAddons.remove(e);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 22,
                                        color: Colors.red.withOpacity(.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ))
                  ?.toList(),
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      widget.pc.checkableAddons ??= [];
                      widget.pc.checkableAddons
                          .add(PaidAddon(localizedName: {}, isSelected: false));
                    });
                  },
                  child: Icon(Icons.add),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                AppLocalizations.of(context).translate('Paid addons'),
                textAlign: TextAlign.center,
              ),
              ...?widget.pc.selectableAddons
                  ?.map((e) => Stack(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                activeColor: kPrimary,
                                value: e.isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    e.isSelected = val;
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: TextEditingController(
                                          text: e.localizedName[selectedLocal]),
                                      onChanged: (val) {
                                        e.localizedName[selectedLocal] = val;
                                      },
                                      decoration:
                                          kinputFiledDecoration.copyWith(
                                              suffixText: selectedLocal,
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('Addon name')),
                                    ),
                                    TextField(
                                      controller: TextEditingController(
                                          text: e.price?.toString() ?? ''),
                                      decoration:
                                          kinputFiledDecoration.copyWith(
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('Price')),
                                      onChanged: (val) {
                                        e.price =
                                            double.parse(val, (s) => null);
                                      },
                                    ),
                                    Divider(
                                      height: 30,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  setState(() {
                                    widget.pc.selectableAddons.remove(e);
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 22,
                                  color: Colors.red.withOpacity(.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ))
                  ?.toList(),
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      widget.pc.selectableAddons ??= [];
                      widget.pc.selectableAddons
                          .add(PaidAddon(localizedName: {}, isSelected: false));
                    });
                  },
                  child: Icon(Icons.add),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).translate('Product images'),
                  ),
                  SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        ...?widget.pc?.images?.map((e) => Stack(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InnerShadow(
                                    shadows: [
                                      BoxShadow(
                                          color: Colors.white.withOpacity(.6),
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          spreadRadius: 2)
                                    ],
                                    child: Container(
                                      margin: EdgeInsets.all(4),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(.3),
                                                offset: Offset(2, 2),
                                                blurRadius: 2,
                                                spreadRadius: 1),
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(.4),
                                                offset: Offset(0, 0),
                                                blurRadius: 2,
                                                spreadRadius: .5)
                                          ],
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image:
                                                  NetworkImage(e.downloadUrl))),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: ButtonTheme(
                                    padding: EdgeInsets.all(0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        splashColor: kPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          await FirebaseStorage.instance
                                              .ref()
                                              .child(e.refPath)
                                              .delete();
                                          setState(() {
                                            widget.pc.images.remove(e);
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 22,
                                          color: Colors.red.withOpacity(.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )),
                        IconButton(
                          onPressed: () async {
                            try {
                              FirestoreImage im = FirestoreImage();
                              var pickedImage = await ImagePicker()
                                  .getImage(source: ImageSource.gallery);

                              if (pickedImage != null) {
                                File file = File(pickedImage.path);
                                Img.Image image_temp =
                                    Img.decodeImage(file.readAsBytesSync());
                                Img.Image resized_img = Img.copyResize(
                                    image_temp,
                                    width: 800,
                                    height: image_temp.height ~/
                                        (image_temp.width / 800));
                                var data =
                                    Img.encodeJpg(resized_img, quality: 60);
                                String filename =
                                    '${Uuid().v4()}${ppp.basename(file.path)}';
                                isUploading.value = true;
                                var imageRef = FirebaseStorage.instance
                                    .ref()
                                    .child('images')
                                    .child(filename);

                                var uploadTask = imageRef.putData(
                                  data,
                                );

//                                  var uploadTask =
//                                      imageRef.putFile(File(pickedImage.path));
                                im.refPath = imageRef.path;
                                var res = await uploadTask.onComplete;
                                if (!uploadTask.isSuccessful)
                                  throw Exception(AppLocalizations.of(context)
                                      .translate('File upload failed'));
                                String url = await res.ref.getDownloadURL();
                                String refPath = imageRef.path;
                                if (!((url?.length ?? 0) > 0)) {
                                  throw Exception(AppLocalizations.of(context)
                                      .translate('File upload failed'));
                                }
                                setState(() {
                                  im.downloadUrl = url;
                                  widget.pc.images ??= [];
                                  widget.pc.images.add(im);
                                });
                              }
                            } catch (e) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return OkDialog(
                                        title: AppLocalizations.of(context)
                                            .translate('Error'),
                                        content: e.message);
                                  });
                            } finally {
                              isUploading.value = false;
                            }
                          },
                          icon: Icon(Icons.add),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              FlatButton(
                color: kPrimary,
                onPressed: () {
                  try {
                    widget.onAddClicked(widget.pc);
                    Navigator.pop(context);
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => OkDialog(
                        title: AppLocalizations.of(context).translate('Error'),
                        content: e.toString(),
                      ),
                    );
                  }
                },
                child: Text(
                  AppLocalizations.of(context).translate('Add'),
                  style: TextStyle(color: kIcons),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsSearch extends SearchDelegate<String> {
  final List<Product> products;
  ProductsSearch({this.products});
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
    final List<Product> suggestionList = query.isEmpty
        ? products.take(products.length).toList()
        : products
            .where((element) => element
                .localizedName[AppLocalizations.of(context).locale.languageCode]
                ?.contains(query))
            .toList();
    suggestionList.sort((a, b) => (a?.order ?? 0) - (b?.order ?? 0));
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) =>
          ValueListenableBuilder<DatabaseUser>(
        valueListenable: viewModel.databaseUser,
        builder: (context, user, child) {
          if (user.role == UserType.admin) {
            return ListView.builder(
              itemBuilder: (context, index) {
                return Slidable(
                  key: Key(suggestionList[index].productDocumentId),
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
                                  viewModel.storeProduct(p).catchError((error) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => OkDialog(
                                        title: AppLocalizations.of(context)
                                            .translate('Error'),
                                        content: error.toString(),
                                      ),
                                    );
                                  });
                                },
                                pc: suggestionList[index],

//
                              );
                            });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          child: Material(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15))),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFABABAB).withOpacity(0.7),
                                    blurRadius: 4.0,
                                    spreadRadius: 3.0,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  color: Colors.black12.withOpacity(0.1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.edit,
                                            color: kIcons,
                                          ),
                                          Text(
                                            AppLocalizations.of(context)
                                                .translate('Edit'),
                                            style: TextStyle(color: kIcons),
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
                        viewModel.deleteProduct(suggestionList[index]);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          child: Material(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15))),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFABABAB).withOpacity(0.7),
                                    blurRadius: 4.0,
                                    spreadRadius: 3.0,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  color: Colors.black12.withOpacity(0.1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.delete,
                                            color: kIcons,
                                          ),
                                          Text(
                                            AppLocalizations.of(context)
                                                .translate('Delete'),
                                            style: TextStyle(color: kIcons),
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
                      p: suggestionList[index],
                    ),
                  ),
                );
              },
              itemCount: suggestionList.length,
            );
          } else {
            return ListView(
              children: <Widget>[
                ...suggestionList.map(
                  (e) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ProductItem(p: e),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
