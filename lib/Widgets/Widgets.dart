import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as Img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/CartItem.dart';
import 'package:male/Models/Category.dart';
import 'package:male/Models/FirestoreImage.dart';
import 'package:male/Models/Order.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/OrderDetailPage.dart';
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
            AppLocalizations.of(context).translate('Cancel'),
            style: TextStyle(color: kPrimary),
          ),
          onPressed: () {
            Navigator.pop(context, 'Cancel');
          },
        ),
        FlatButton(
          splashColor: kPrimary.withOpacity(.2),
          child: Text(
            AppLocalizations.of(context).translate('Ok'),
            style: TextStyle(color: kPrimary),
          ),
          onPressed: () {
            Navigator.pop(context, 'Ok');
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
                          color: kPrimary,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('Add to cart'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
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

class OrdersSummaryWidget extends StatelessWidget {
  final child;
  final List<Order> orders;
  const OrdersSummaryWidget({this.orders, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Theme(
        data: ThemeData(accentColor: kPrimary),
        child: ExpansionTile(
          leading:
              Text(AppLocalizations.of(context).translate('Orders summary')),
          title: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${AppLocalizations.of(context).translate('Orders count')}: ${orders.length.toString()}',
              textAlign: TextAlign.left,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Orders",
                  textAlign: TextAlign.center,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(
                          label: Text(AppLocalizations.of(context)
                              .translate('Order status'))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)
                              .translate('Quantity'))),
                      DataColumn(
                          label: Text(
                              AppLocalizations.of(context).translate('Price')))
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text(AppLocalizations.of(context)
                            .translate('Total orders'))),
                        DataCell(Text((orders?.length ?? 0).toString())),
                        DataCell(Text(
                          '${orders?.fold<double>(0, (previousValue, element) => previousValue + (element.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1))) + element.deliveryFee)?.toStringAsFixed(2) ?? 0}₾',
                          style: TextStyle(fontFamily: 'Sans'),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(AppLocalizations.of(context)
                            .translate('Completed orders'))),
                        DataCell(Text((orders
                                    ?.where((element) => element
                                        .deliveryStatusSteps[
                                            DeliveryStatus.Completed]
                                        .isActive)
                                    ?.length ??
                                0)
                            .toString())),
                        DataCell(Text(
                          '${orders?.where((element) => element.deliveryStatusSteps[DeliveryStatus.Completed].isActive)?.fold<double>(0, (previousValue, element) => previousValue + (element.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1))) + element.deliveryFee)?.toStringAsFixed(2) ?? 0}₾',
                          style: TextStyle(fontFamily: 'Sans'),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(AppLocalizations.of(context)
                            .translate('Accepted orders'))),
                        DataCell(Text((orders
                                    ?.where((element) => element
                                        .deliveryStatusSteps[
                                            DeliveryStatus.Accepted]
                                        .isActive)
                                    ?.length ??
                                0)
                            .toString())),
                        DataCell(Text(
                          '${orders?.where((element) => element.deliveryStatusSteps[DeliveryStatus.Accepted].isActive)?.fold<double>(0, (previousValue, element) => previousValue + (element.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1))) + element.deliveryFee)?.toStringAsFixed(2) ?? 0}₾',
                          style: TextStyle(fontFamily: 'Sans'),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(AppLocalizations.of(context)
                            .translate('Pending orders'))),
                        DataCell(Text((orders
                                    ?.where((element) => element
                                        .deliveryStatusSteps[
                                            DeliveryStatus.Pending]
                                        .isActive)
                                    ?.length ??
                                0)
                            .toString())),
                        DataCell(Text(
                          '${orders?.where((element) => element.deliveryStatusSteps[DeliveryStatus.Pending].isActive)?.fold<double>(0, (previousValue, element) => previousValue + (element.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1))) + element.deliveryFee)?.toStringAsFixed(2) ?? 0}₾',
                          style: TextStyle(fontFamily: 'Sans'),
                        )),
                      ]),
                      DataRow(cells: [
                        DataCell(Text(AppLocalizations.of(context)
                            .translate('Canceled orders'))),
                        DataCell(Text((orders
                                    ?.where((element) =>
                                        element
                                            .deliveryStatusSteps[
                                                DeliveryStatus.Canceled]
                                            ?.isActive ??
                                        false)
                                    ?.length ??
                                0)
                            .toString())),
                        DataCell(Text(
                          '${orders?.where((element) => element.deliveryStatusSteps[DeliveryStatus.Canceled]?.isActive ?? false)?.fold<double>(0, (previousValue, element) => previousValue + (element.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1))) + element.deliveryFee)?.toStringAsFixed(2) ?? 0}₾',
                          style: TextStyle(fontFamily: 'Sans'),
                        )),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            Divider(),
            if (child != null) child
          ],
        ),
      ),
    );
  }
}

class OrderWidget extends StatelessWidget {
  final bool showIsSeenIcon;
  final Order order;
  OrderWidget({this.order, this.showIsSeenIcon = false});
  @override
  Widget build(BuildContext context) {
    print(order.isSeen);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 2,
          child: RawMaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onPressed: () {
              if (showIsSeenIcon) {
                if (!order.isSeen)
                  FirebaseFirestore.instance
                      .collection('/orders')
                      .doc(order.documentId)
                      .update({'isSeen': true});
              }
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => OrderDetailPage(
                  orderR: order,
                ),
              ));
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          topLeft: Radius.circular(4))),
                  elevation: 2,
                  color: kPrimary,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat.yMd().add_Hms().format(
                              (order.serverTime as Timestamp)?.toDate() ??
                                  DateTime(0000)),
                          style: TextStyle(
                              color: kIcons,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        if (showIsSeenIcon && !order.isSeen)
                          Icon(
                            Icons.star,
                            color: kIcons,
                          ),
                        Text(
                          '${AppLocalizations.of(context).translate('Order id')}: ${order.orderId?.toString() ?? ''}',
                          style: TextStyle(color: kIcons),
                        )
                      ],
                    ),
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${AppLocalizations.of(context).translate('Order price')}: ₾${(order.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1)))?.toStringAsFixed(2) ?? '0'}',
                          style: TextStyle(color: kPrimary, fontFamily: 'Sans'),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      Flexible(
                        child: Text(
                          '${AppLocalizations.of(context).translate('Delivery fee')}: ₾${order.deliveryFee?.toString() ?? '0'}',
                          style: TextStyle(color: kPrimary, fontFamily: 'Sans'),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2)),
                          elevation: 4,
                          color: Colors.grey.shade300,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                Text(AppLocalizations.of(context)
                                    .translate('Order status')),
                                Text(AppLocalizations.of(context).translate(
                                    EnumToString.convertToString(order
                                        .deliveryStatusSteps.entries
                                        .firstWhere(
                                            (element) => element.value.isActive)
                                        .key))),
                              ],
                            ),
                          )),
                      Material(
                          color: Colors.grey.shade300,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2)),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                Text(AppLocalizations.of(context)
                                    .translate('Payment status')),
                                Text(AppLocalizations.of(context).translate(
                                    EnumToString.parse(order.paymentStatus))),
                              ],
                            ),
                          ))
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }
}

class YouHaveNothingWidgets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            constraints: BoxConstraints.expand(),
            child: SvgPicture.asset('assets/svg/NoItem.svg')),
        Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 4),
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                AppLocalizations.of(context).translate('You have nothing here'),
                style: TextStyle(fontSize: 16, color: kPrimary, shadows: [
                  BoxShadow(
                      color: Colors.white.withOpacity(1),
                      blurRadius: 10.0,
                      spreadRadius: 2.0)
                ]),
              )),
        )
      ],
    );
  }
}
