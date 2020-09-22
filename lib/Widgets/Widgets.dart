import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as Img;
import 'package:image_picker/image_picker.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/CartItem.dart';
import 'package:male/Models/Category.dart';
import 'package:male/Models/FirestoreImage.dart';
import 'package:male/Models/Product.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:path/path.dart' as ppp;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

ImageProvider safeNetworkImage(String url) {
  if ((url?.length ?? 0) > 0) return NetworkImage(url);
  return AssetImage('assets/placeHolder.png');
}

class InnerShadow extends SingleChildRenderObjectWidget {
  const InnerShadow({
    Key key,
    this.shadows = const <Shadow>[],
    Widget child,
  }) : super(key: key, child: child);

  final List<Shadow> shadows;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final renderObject = _RenderInnerShadow();
    updateRenderObject(context, renderObject);
    return renderObject;
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderInnerShadow renderObject) {
    renderObject.shadows = shadows;
  }
}

class _RenderInnerShadow extends RenderProxyBox {
  List<Shadow> shadows;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final bounds = offset & size;
    final canvas = context.canvas;

    canvas.saveLayer(bounds, Paint());
    context.paintChild(child, offset);

    for (final shadow in shadows) {
      final shadowRect = bounds.inflate(shadow.blurSigma);
      final shadowPaint = Paint()
        ..blendMode = BlendMode.srcATop
        ..colorFilter = ColorFilter.mode(shadow.color, BlendMode.srcOut)
        ..imageFilter = ImageFilter.blur(
            sigmaX: shadow.blurSigma, sigmaY: shadow.blurSigma);
      canvas
        ..saveLayer(shadowRect, shadowPaint)
        ..translate(shadow.offset.dx, shadow.offset.dy);
      context.paintChild(child, offset);
      canvas.restore();
    }

    canvas.restore();
  }
}

class OkDialog extends StatelessWidget {
  const OkDialog({@required this.content, @required this.title});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: <Widget>[
        FlatButton(
          splashColor: kPrimary.withOpacity(.2),
          child: Text(
            AppLocalizations.of(context).translate('Ok'),
            style: TextStyle(color: kPrimary),
          ),
          onPressed: () {
            Navigator.pop(
                context, AppLocalizations.of(context).translate('Ok'));
          },
        )
      ],
      title: Text(title),
      content: Text(content),
    );
  }
}

class SlideActionElement extends StatelessWidget {
  final iconData;
  final Color color;
  final String text;
  SlideActionElement({this.text, this.color, this.iconData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15.0))),
      child: Material(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
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
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              color: Colors.black12.withOpacity(0.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Icon(
                            iconData,
                            color: kIcons,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            text,
                            style: TextStyle(color: kIcons),
                          ),
                        ),
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
    );
  }
}

class CategoryItemWidget extends StatelessWidget {
  final Function onUpPress;
  final Function onDownPress;
  final Category category;
  const CategoryItemWidget({this.category, this.onDownPress, this.onUpPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image(
            image: NetworkImage(category.image.downloadUrl),
            height: 200,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
          Text(
            category.localizedName[
                    AppLocalizations.of(context).locale.languageCode] ??
                category
                    .localizedName[AppLocalizations.supportedLocales.first] ??
                '',
            style: TextStyle(
                color: kIcons, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Positioned.fill(
              child: RawMaterialButton(
            onPressed: () {},
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (onUpPress != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: RawMaterialButton(
                      onPressed: onUpPress,
                      splashColor: kPrimary.withOpacity(0.3),
                      shape: CircleBorder(),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: kPrimary.withOpacity(0.3),
                      ),
                    ),
                  ),
                if (onDownPress != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: RawMaterialButton(
                      onPressed: onDownPress,
                      splashColor: kPrimary.withOpacity(0.3),
                      shape: CircleBorder(),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: kPrimary.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class AddCategoryWidget extends StatefulWidget {
  final Function(Category) onAddClicked;
  AddCategoryWidget({this.onAddClicked});

  @override
  _AddCategoryWidgetState createState() => _AddCategoryWidgetState();
}

class _AddCategoryWidgetState extends State<AddCategoryWidget> {
  TextEditingController categoryController = TextEditingController();
  String selectedLocal = AppLocalizations.supportedLocales.first.languageCode;
  ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  Category category = Category(image: FirestoreImage(), localizedName: {});
  bool addClicked = false;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    try {
      if (!addClicked && (category.image.refPath?.length ?? 0) > 0) {
        FirebaseStorage.instance
            .ref()
            .child(category.image.refPath)
            .delete()
            .whenComplete(() {
          category.image.refPath = null;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                                categoryController.text =
                                    category.localizedName[selectedLocal] ?? '';
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
            controller: categoryController,
            onChanged: (value) {
              category.localizedName[selectedLocal] = value;
            },
            style: TextStyle(),
            cursorColor: kPrimary,
            decoration: InputDecoration(
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
                    AppLocalizations.of(context).translate("Category Name")),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 8),
              child: Column(
                children: <Widget>[
                  Text(
                      AppLocalizations.of(context).translate('Category image')),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isUploading,
                      builder: (context, value, child) {
                        return value
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(kPrimary),
                                ),
                              )
                            : child;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: (category.image.downloadUrl?.length ?? 0) > 0
                            ? Stack(
                                children: <Widget>[
                                  Center(
                                    child: Image(
                                      image: NetworkImage(
                                          category.image.downloadUrl),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: RawMaterialButton(
                                        shape: CircleBorder(),
                                        onPressed: () {
                                          try {
                                            if ((category.image.refPath
                                                        ?.length ??
                                                    0) >
                                                0) {
                                              FirebaseStorage.instance
                                                  .ref()
                                                  .child(category.image.refPath)
                                                  .delete()
                                                  .whenComplete(() {
                                                category.image.refPath = null;
                                              });
                                            }
                                          } catch (e) {}

                                          setState(() {
                                            category.image.downloadUrl = null;
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : IconButton(
                                onPressed: () async {
                                  try {
                                    var pickedImage = await ImagePicker()
                                        .getImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      File file = File(pickedImage.path);
                                      Img.Image image_temp = Img.decodeImage(
                                          file.readAsBytesSync());
                                      Img.Image resized_img = Img.copyResize(
                                          image_temp,
                                          width: 800,
                                          height: image_temp.height ~/
                                              (image_temp.width / 800));
                                      var data = Img.encodeJpg(resized_img,
                                          quality: 60);

                                      String filename =
                                          '${Uuid().v4()}${ppp.basename(file.path)}';
                                      isUploading.value = true;
                                      var imageRef = FirebaseStorage.instance
                                          .ref()
                                          .child('images')
                                          .child(filename);
                                      var uploadTask = imageRef.putData(data);
//                                      var uploadTask = imageRef
//                                          .putFile(File(pickedImage.path));
                                      category.image.refPath = imageRef.path;
                                      var res = await uploadTask.onComplete;
                                      if (!uploadTask.isSuccessful)
                                        throw Exception(AppLocalizations.of(
                                                context)
                                            .translate('File upload failed'));
                                      String url =
                                          await res.ref.getDownloadURL();
                                      String refPath = imageRef.path;
                                      if (!((url?.length ?? 0) > 0)) {
                                        throw Exception(AppLocalizations.of(
                                                context)
                                            .translate('File upload failed'));
                                      }
                                      setState(() {
                                        category.image.downloadUrl = url;
                                      });
                                    }
                                  } catch (e) {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return OkDialog(
                                              title:
                                                  AppLocalizations.of(context)
                                                      .translate('Error'),
                                              content: e.message);
                                        });
                                  } finally {
                                    isUploading.value = false;
                                  }
                                },
                                icon: Icon(Icons.add),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FlatButton(
            color: kPrimary,
            onPressed: () {
              if (!((category.image.downloadUrl?.length ?? 0) > 0 ||
                  (category.image.refPath?.length ?? 0) > 0)) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return OkDialog(
                          title:
                              AppLocalizations.of(context).translate('Error'),
                          content: AppLocalizations.of(context)
                              .translate('Please pick an image'));
                    });
                return;
              }
              if (!((category
                          .localizedName[
                              AppLocalizations.of(context).locale.languageCode]
                          ?.length ??
                      0) >
                  0)) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return OkDialog(
                          title:
                              AppLocalizations.of(context).translate('Error'),
                          content: AppLocalizations.of(context).translate(
                              'Please enter a category name in primary language'));
                    });
                return;
              }
              widget.onAddClicked(category);
              addClicked = true;
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context).translate('Add'),
              style: TextStyle(color: kIcons),
            ),
          ),
        ],
      ),
    );
  }
}

class EditCategoryWidget extends StatefulWidget {
  final Category category;
  final Function(Category) onEditClicked;
  EditCategoryWidget({@required this.onEditClicked, @required this.category});

  @override
  _EditCategoryWidgetState createState() => _EditCategoryWidgetState();
}

class _EditCategoryWidgetState extends State<EditCategoryWidget> {
  String selectedLocal = AppLocalizations.supportedLocales.first.languageCode;
  TextEditingController categoryController;
  ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  @override
  void initState() {
    super.initState();
    categoryController = TextEditingController(
        text: widget.category.localizedName[selectedLocal]);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.category.localizedName);
    return Container(
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
                                categoryController.text = widget.category
                                        .localizedName[selectedLocal] ??
                                    '';
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
            controller: categoryController,
            onChanged: (value) {
              widget.category.localizedName[selectedLocal] = value;
            },
            style: TextStyle(),
            cursorColor: kPrimary,
            decoration: InputDecoration(
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
                    AppLocalizations.of(context).translate("Category Name")),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 8),
              child: Column(
                children: <Widget>[
                  Text(
                      AppLocalizations.of(context).translate('Category image')),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isUploading,
                      builder: (context, value, child) {
                        return value
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(kPrimary),
                                ),
                              )
                            : child;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: (widget.category.image.downloadUrl?.length ??
                                    0) >
                                0
                            ? Stack(
                                children: <Widget>[
                                  Center(
                                    child: Image(
                                      image: NetworkImage(
                                          widget.category.image.downloadUrl),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: RawMaterialButton(
                                        shape: CircleBorder(),
                                        onPressed: () {
                                          setState(() {
                                            widget.category.image.refPath =
                                                null;
                                            widget.category.image.downloadUrl =
                                                null;
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : IconButton(
                                onPressed: () async {
                                  try {
                                    var pickedImage = await ImagePicker()
                                        .getImage(source: ImageSource.gallery);
                                    if (pickedImage != null) {
                                      File file = File(pickedImage.path);
                                      String filename =
                                          '${Uuid().v4()}${ppp.basename(file.path)}';
                                      isUploading.value = true;
                                      var imageRef = FirebaseStorage.instance
                                          .ref()
                                          .child('images')
                                          .child(filename);
                                      var uploadTask = imageRef
                                          .putFile(File(pickedImage.path));
                                      widget.category.image.refPath =
                                          imageRef.path;
                                      var res = await uploadTask.onComplete;
                                      if (!uploadTask.isSuccessful)
                                        throw Exception(AppLocalizations.of(
                                                context)
                                            .translate('File upload failed'));
                                      String url =
                                          await res.ref.getDownloadURL();
                                      String refPath = imageRef.path;
                                      if (!((url?.length ?? 0) > 0)) {
                                        throw Exception(AppLocalizations.of(
                                                context)
                                            .translate('File upload failed'));
                                      }
                                      setState(() {
                                        widget.category.image.downloadUrl = url;
                                      });
                                    }
                                  } catch (e) {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return OkDialog(
                                              title:
                                                  AppLocalizations.of(context)
                                                      .translate('Error'),
                                              content: e.message);
                                        });
                                  } finally {
                                    isUploading.value = false;
                                  }
                                },
                                icon: Icon(Icons.add),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FlatButton(
            color: kPrimary,
            onPressed: () {
              if (!((widget.category.image.downloadUrl?.length ?? 0) > 0 ||
                  (widget.category.image.refPath?.length ?? 0) > 0)) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return OkDialog(
                          title:
                              AppLocalizations.of(context).translate('Error'),
                          content: AppLocalizations.of(context)
                              .translate('Please pick an image'));
                    });
                return;
              }
              if (!((widget
                          .category
                          .localizedName[
                              AppLocalizations.of(context).locale.languageCode]
                          ?.length ??
                      0) >
                  0)) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return OkDialog(
                          title:
                              AppLocalizations.of(context).translate('Error'),
                          content: AppLocalizations.of(context).translate(
                              'Please enter a category name in primary language'));
                    });
                return;
              }
              widget.onEditClicked(widget.category);
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context).translate('Add changes'),
              style: TextStyle(color: kIcons),
            ),
          ),
        ],
      ),
    );
  }
}

class CartControl extends StatelessWidget {
  const CartControl({
    Key key,
    @required this.product,
  }) : super(key: key);

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) => Align(
          alignment: Alignment.topRight,
          child: ValueListenableBuilder<List<CartItem>>(
            builder: (context, value, child) {
              return Container(
                child: () {
                  CartItem inCartProduct = value.firstWhere(
                      (element) => element.product == product,
                      orElse: () => null);
                  return inCartProduct == null
                      ? FlatButton(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('Add to cart'),
                            style:
                                TextStyle(color: Colors.black.withOpacity(.8)),
                          ),
                          onPressed: () {
                            product.quantity = 1;
                            viewModel.storeCart(product);
                          })
                      : Container(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white70,
                                border: Border.all(
                                    color: Colors.black12.withOpacity(0.1))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                /// Decrease of value item
                                Material(
                                  child: InkWell(
                                    onTap: () {
                                      try {
                                        inCartProduct.product.quantity ??= 0;
                                        if (inCartProduct.product.quantity ==
                                            0) {
                                          return;
                                        }
                                        inCartProduct.product.quantity--;
                                        if (!(inCartProduct.product.quantity >
                                            0)) {
                                          FirebaseFirestore.instance
                                              .collection('/cart')
                                              .doc(inCartProduct.documentId)
                                              .delete();
                                          return;
                                        }
                                        FirebaseFirestore.instance
                                            .collection('/cart')
                                            .doc(inCartProduct.documentId)
                                            .set(inCartProduct.toJson(),
                                                SetOptions(merge: true));
                                      } catch (e) {}
                                    },
                                    child: Container(
                                      height: 30.0,
                                      width: 30.0,
                                      decoration: BoxDecoration(
                                          border: Border(
                                              right: BorderSide(
                                                  color: Colors.black12
                                                      .withOpacity(0.1)))),
                                      child: Center(child: Text("-")),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0),
                                  child: Text(inCartProduct.product.quantity
                                          ?.toString() ??
                                      '0'),
                                ),

                                /// Increasing value of item
                                Material(
                                  child: InkWell(
                                    onTap: () {
                                      try {
                                        inCartProduct.product.quantity ??= 0;
                                        if (inCartProduct
                                                    .product.quantityInSupply !=
                                                null &&
                                            inCartProduct
                                                    .product.quantityInSupply <
                                                inCartProduct.product.quantity +
                                                    1) return;
                                        inCartProduct.product.quantity++;
                                        FirebaseFirestore.instance
                                            .collection('/cart')
                                            .doc(inCartProduct.documentId)
                                            .set(inCartProduct.toJson(),
                                                SetOptions(merge: true));
                                      } catch (e) {}
                                    },
                                    child: Container(
                                      height: 30.0,
                                      width: 28.0,
                                      decoration: BoxDecoration(
                                          border: Border(
                                              left: BorderSide(
                                                  color: Colors.black12
                                                      .withOpacity(0.1)))),
                                      child: Center(child: Text("+")),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
//                                              child: Text(inCartProduct
//                                                      .product
//                                                      .productsForms[widget
//                                                          .p.selectedIndex]
//                                                      .quantity
//                                                      ?.toString() ??
//                                                  '0'),
                        );
                }(),
              );
            },
            valueListenable: viewModel.cart,
          )),
    );
  }
}
