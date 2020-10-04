import 'package:flutter/material.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/CartItem.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/Uitls/Utils.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/CartPage.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final Product p;
  ProductDetailPage({this.p});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(getLocalizedName(widget.p.localizedName, context)),
          actions: [
            ValueListenableBuilder<List<CartItem>>(
              valueListenable: viewModel.cart,
              builder: (context, cart, child) {
                return Stack(
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
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: new Text(
                                      viewModel.cart.value.length.toString(),
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
                );
              },
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return Scaffold(
                          appBar: AppBar(
                            title: Text(
                                AppLocalizations.of(context).translate('Cart')),
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
        body: ValueListenableBuilder<DatabaseUser>(
          valueListenable: viewModel.databaseUser,
          builder: (context, user, child) => Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 10,
                  ),
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
                                getLocalizedName(
                                    widget.p.localizedName, context),
                                style: kProductNameTextStyle,
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              ...?widget.p.addonDescriptions.map((e) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${getLocalizedName(e.localizedAddonDescriptionName, context)}',
                                          style: kDescriptionHeaderTextStyle,
                                        ),
                                      ),
                                      VerticalDivider(
                                        width: 4,
                                      ),
                                      Flexible(
                                        child: Text(
                                          '${getLocalizedName(e.localizedAddonDescription, context)}',
                                          style: kDescriptionTextStyle,
                                        ),
                                      ),
                                    ],
                                  )),
                              if (widget.p.quantityInSupply != null)
                                Row(
                                  children: [
                                    Text(
                                      '${AppLocalizations.of(context).translate('Quantity in supply')}: ',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                    Text(
                                      widget.p.quantityInSupply.toString(),
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ...?widget.p.checkableAddons
                                  ?.map((e) => Row(
                                        children: [
                                          Radio(
                                            activeColor: kPrimary,
                                            value: e,
                                            groupValue: widget?.p?.checkedAddon,
                                            onChanged: (val) {
                                              setState(() {
                                                widget.p.checkableAddons
                                                    .forEach((element) {
                                                  element.isSelected = false;
                                                });
                                                (val as PaidAddon).isSelected =
                                                    true;
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  getLocalizedName(
                                                      e.localizedName, context),
                                                  style: kDescriptionTextStyle
                                                      .copyWith(
                                                          color: kPrimary),
                                                ),
                                                if (e.price != null)
                                                  Text(
                                                    '+${e.price.toString()}₾',
                                                    style: kAddonPriceTextStyle,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ))
                                  ?.toList(),
                            ],
                          ),
//
                        ),
                      ),
                    ],
                  ),
                  ...?widget.p.selectableAddons
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getLocalizedName(
                                            e.localizedName, context),
                                        style: kDescriptionTextStyle,
                                      ),
                                      if (e.price != null)
                                        Text(
                                          '+${e.price?.toString() ?? ''}₾',
                                          style: TextStyle(
                                            fontFamily: 'Sans',
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ))
                      ?.toList(),
                  Text(
                    '₾${widget.p.totalProductPrice.toString()}',
                    style: kPriceTextStyle,
                    textAlign: TextAlign.right,
                  ),
                  if (user?.role == UserType.user &&
                      ((widget.p.quantityInSupply ?? 0) > 0 ||
                          widget.p.quantityInSupply == null))
                    CartControl(
                      product: widget.p,
                    ),
                  Divider(),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('Photos'),
                        style: TextStyle(
                            fontFamily: "Sofia",
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.justify,
                      ),
                      InkWell(
                          onTap: () {
                            Navigator.of(context).push(PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (BuildContext context, _, __) {
                                return Scaffold(
                                  appBar: AppBar(
                                    title: Text(getLocalizedName(
                                        widget.p.localizedName, context)),
                                  ),
                                  body: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0,
                                        bottom: 5.0,
                                        left: 5.0,
                                        right: 5.0),
                                    child: PageView(
                                      physics: BouncingScrollPhysics(),
                                      children: [
                                        ...?widget.p.images
                                            .map((e) => Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: NetworkImage(
                                                            e.downloadUrl),
                                                        fit: BoxFit.cover),
                                                  ),
                                                ))
                                      ],
                                      controller:
                                          PageController(initialPage: 0),
                                      scrollDirection: Axis.horizontal,
                                    ),
                                  ),
                                );
                              },
                            ));
                          },
                          child: Text(
                              AppLocalizations.of(context).translate('See all'),
                              style: TextStyle(
                                  fontFamily: "Sofia",
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w300)))
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),
                  Container(
                    height: 140,
                    child: ListView(
                      children: [
                        SizedBox(
                          width: 10.0,
                        ),
                        ...?widget.p.images
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Material(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10.0)),
                                      child: InkWell(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10.0)),
                                        onTap: () {
                                          Navigator.of(context).push(
                                              PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder:
                                                      (BuildContext context, _,
                                                          __) {
                                                    return new Material(
                                                      color: Colors.black54,
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 5.0,
                                                                right: 5.0,
                                                                top: 0.0,
                                                                bottom: 0.0),
                                                        child: InkWell(
                                                          child: Hero(
                                                              tag:
                                                                  "hero-grid-${e.refPath}",
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                        .only(
                                                                    left: 5.0,
                                                                    right: 5.0,
                                                                    top: 160.0,
                                                                    bottom:
                                                                        160.0),
                                                                child:
                                                                    Container(
                                                                  height: 500.0,
                                                                  width: double
                                                                      .infinity,
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.all(Radius.circular(
                                                                              10.0)),
                                                                      image: DecorationImage(
                                                                          image: NetworkImage(e
                                                                              .downloadUrl),
                                                                          fit: BoxFit
                                                                              .cover)),
                                                                ),
                                                              )),
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  transitionDuration: Duration(
                                                      milliseconds: 500)));
                                        },
                                        child: Hero(
                                          tag: "hero-grid-${e.refPath}",
                                          child: Container(
                                            height: 110.0,
                                            width: 140.0,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: NetworkImage(
                                                        e.downloadUrl),
                                                    fit: BoxFit.cover),
                                                color: Colors.black12,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10.0)),
                                                boxShadow: [
                                                  BoxShadow(
                                                      blurRadius: 5.0,
                                                      color: Colors.black12
                                                          .withOpacity(0.1),
                                                      spreadRadius: 2.0)
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5.0,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 30.0, left: 20.0, right: 20.0, bottom: 50.0),
                    child: Text(
                      getLocalizedName(widget.p.localizedDescription, context),
                      style: kDescriptionTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
