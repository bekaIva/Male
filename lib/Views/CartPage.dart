import 'dart:convert';

import 'package:audioplayers/audio_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Address.dart';
import 'package:male/Models/CartItem.dart';
import 'package:male/Models/Exceptions.dart';
import 'package:male/Models/Order.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/Settings.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/Uitls/Utils.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/UnipayCheckoutPage.dart';
import 'package:male/Widgets/AddressesList.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

import 'AddAddressPage.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  TextEditingController messageController = TextEditingController();
  ValueNotifier<bool> ordering = ValueNotifier<bool>(false);
  PaymentMethods paymentMethod;
  UserAddress selectedAddress;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ordering,
      builder: (context, value, child) {
        return Stack(
          children: [
            child,
            if (value)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(kPrimary),
                ),
              )
          ],
        );
      },
      child: Consumer2<MainViewModel, User>(
        builder: (context, viewModel, user, child) {
          return user != null
              ? ValueListenableBuilder<List<CartItem>>(
                  valueListenable: viewModel.cart,
                  builder: (context, cart, child) {
                    double totalPrice = cart.fold<double>(
                        0,
                        (previousValue, element) =>
                            previousValue +
                            element.product.totalProductPrice *
                                element.product.quantity);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: ValueListenableBuilder<AppSettings>(
                          valueListenable: viewModel.settings,
                          builder: (context, settigns, child) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Theme(
                                data: ThemeData(
                                  accentColor: kPrimary,
                                  textTheme: Theme.of(context)
                                      .textTheme
                                      .copyWith(
                                          subtitle1: TextStyle(
                                              color: Colors.black
                                                  .withOpacity(.7))),
                                ),
                                child: ExpansionTile(
                                  leading: Text(
                                    AppLocalizations.of(context)
                                        .translate('Cart'),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                          '${cart.fold(0, (previousValue, element) => previousValue + element.product.quantity)} ${AppLocalizations.of(context).translate('Product')} | '),
                                      Text(
                                        '₾${totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(fontFamily: 'Sans'),
                                      )
                                    ],
                                  ),
                                  children: [
                                    ...viewModel.cart.value
                                        .map((e) => CartItemWidget(
                                              cartItemChanged: () {
                                                setState(() {});
                                              },
                                              p: e,
                                            ))
                                        .toList(),
                                    if (cart.length > 0)
                                      FlatButton(
                                        child: Text(AppLocalizations.of(context)
                                            .translate('Clear')),
                                        onPressed: () async {
                                          var res = await showDialog<String>(
                                            context: context,
                                            builder: (context) => OkDialog(
                                                content:
                                                    '${AppLocalizations.of(context).translate('Are you sure you want to empty your cart?')}',
                                                title: AppLocalizations.of(
                                                        context)
                                                    .translate('Clear cart')),
                                          );
                                          if (res == 'Ok') {
                                            cart.forEach((element) {
                                              FirebaseFirestore.instance
                                                  .collection('/cart')
                                                  .doc(element.documentId)
                                                  .delete();
                                            });
                                          }
                                        },
                                      )
                                  ],
                                ),
                              ),
                              Theme(
                                data: ThemeData(
                                  accentColor: kPrimary,
                                  textTheme: Theme.of(context)
                                      .textTheme
                                      .copyWith(
                                        subtitle1: TextStyle(
                                          color: Colors.black.withOpacity(.7),
                                        ),
                                      ),
                                ),
                                child: ExpansionTile(
                                  title: Text(AppLocalizations.of(context)
                                      .translate('Addresses')),
                                  children: [
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('userAddresses')
                                          .where('uid', isEqualTo: user.uid)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.data != null) {
                                          return AddressesList(
                                            addressSelected: (address) {
                                              selectedAddress = address;
                                            },
                                            userAddresses: snapshot.data.docs
                                                .map((e) =>
                                                    UserAddress.fromDocument(e))
                                                .toList(),
                                          );
                                        }
                                        return Container();
                                      },
                                    ),
                                    FlatButton(
                                      splashColor: kPrimary.withOpacity(0.2),
                                      highlightColor: kPrimary.withOpacity(.2),
                                      onPressed: () async {
                                        var userAddress =
                                            await Navigator.push<UserAddress>(
                                                context,
                                                MaterialPageRoute<UserAddress>(
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
                              Theme(
                                data: ThemeData(
                                  accentColor: kPrimary,
                                  textTheme: Theme.of(context)
                                      .textTheme
                                      .copyWith(
                                        subtitle1: TextStyle(
                                          color: Colors.black.withOpacity(.7),
                                        ),
                                      ),
                                ),
                                child: ExpansionTile(
                                  title: Text(AppLocalizations.of(context)
                                      .translate('Payment methods')),
                                  children: [
                                    RadioListTile(
                                      title: Text(AppLocalizations.of(context)
                                          .translate('Debit / Credit Card')),
                                      value: paymentMethod,
                                      groupValue: PaymentMethods.CreditCard,
                                      onChanged: (val) {
                                        setState(() {
                                          paymentMethod =
                                              PaymentMethods.CreditCard;
                                        });
                                      },
                                    ),
                                    RadioListTile(
                                      title: Text(AppLocalizations.of(context)
                                          .translate('By Cash')),
                                      value: paymentMethod,
                                      groupValue: PaymentMethods.ByCash,
                                      onChanged: (val) {
                                        setState(() {
                                          paymentMethod = PaymentMethods.ByCash;
                                        });
                                      },
                                    )
                                  ],
                                ),
                              ),
                              Divider(
                                height: 20,
                                color: Colors.grey,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('Price'),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 16, right: 16, top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppLocalizations.of(context)
                                        .translate('Delivery fee')),
                                    Text(
                                      '₾${(totalPrice == 0 ? 0 : totalPrice > settigns.minimumOrderPrice ? 0 : settigns.deliveryFeeUnderMaximumOrderPrice).toString()}',
                                      style: TextStyle(
                                          fontFamily: 'Sans',
                                          color: totalPrice >
                                                  settigns.minimumOrderPrice
                                              ? Colors.green
                                              : Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(),
                              Padding(
                                padding: EdgeInsets.only(
                                  right: 16,
                                  left: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppLocalizations.of(context)
                                        .translate('Total price')),
                                    Text(
                                      '₾${(totalPrice == 0 ? 0 : totalPrice > settigns.minimumOrderPrice ? totalPrice : totalPrice + settigns.deliveryFeeUnderMaximumOrderPrice).toStringAsFixed(2)}',
                                      style: TextStyle(fontFamily: 'Sans'),
                                    )
                                  ],
                                ),
                              ),
                              if (totalPrice > 0 && user != null)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Divider(),
                                      TextField(
                                        controller: messageController,
                                        style: kDescriptionTextStyle,
                                        maxLines: null,
                                        onChanged: (message) {},
                                        cursorColor: kPrimary,
                                        decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'Leave us a message')),
                                      ),
                                      FlatButton(
                                        color: kPrimary,
                                        onPressed: () async {
                                          try {
                                            if (totalPrice >
                                                settigns.maximumOrderPrice) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => OkDialog(
                                                  title: AppLocalizations.of(
                                                          context)
                                                      .translate('Error'),
                                                  content:
                                                      '${AppLocalizations.of(context).translate('The order price exceeds the maximum amount')}! ${AppLocalizations.of(context).translate('Maximum order price')}[${settigns.maximumOrderPrice.toString()}]',
                                                ),
                                              );
                                              return;
                                            }
                                            ordering.value = true;
                                            var totalPriceWithDelivery =
                                                totalPrice >
                                                        settigns
                                                            .minimumOrderPrice
                                                    ? totalPrice
                                                    : totalPrice +
                                                        settigns
                                                            .deliveryFeeUnderMaximumOrderPrice;
                                            if (selectedAddress == null)
                                              throw new MessageException(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'Address not selected'));
                                            if (settigns.stopOrdering) {
                                              throw new MessageException(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'The service is temporarily unavailable'));
                                            }
                                            if (paymentMethod == null)
                                              throw new MessageException(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'Payment method not selected'));
                                            var o = Order(
                                                orderMessage:
                                                    messageController.text,
                                                deliveryStatusSteps: {
                                                  DeliveryStatus.Pending:
                                                      DeliveryStatusStep(
                                                          isActive: true,
                                                          creationTimestamp:
                                                              FieldValue
                                                                  .serverTimestamp(),
                                                          stepState: StepState
                                                              .indexed),
                                                  DeliveryStatus.Accepted:
                                                      DeliveryStatusStep(
                                                          isActive: false,
                                                          stepState: StepState
                                                              .indexed),
                                                  DeliveryStatus.Completed:
                                                      DeliveryStatusStep(
                                                          isActive: false,
                                                          stepState:
                                                              StepState.indexed)
                                                },
                                                orderId:
                                                    viewModel.lastOrderId ?? 0,
                                                isSeen: false,
                                                serverTime: FieldValue
                                                    .serverTimestamp(),
                                                uid: user.uid,
                                                deliveryAddress:
                                                    selectedAddress,
                                                paymentMethod: paymentMethod,
                                                products: cart
                                                    .map((e) => e.product)
                                                    .toList(),
                                                deliveryFee: totalPrice == 0
                                                    ? 0
                                                    : totalPrice >
                                                            settigns
                                                                .minimumOrderPrice
                                                        ? 0
                                                        : settigns
                                                            .deliveryFeeUnderMaximumOrderPrice);
                                            var value = await FirebaseFirestore
                                                .instance
                                                .collection('/orders')
                                                .add(o.toJson());

                                            FirebaseFirestore.instance
                                                .collection('/settings')
                                                .doc('ordersCounterDocument')
                                                .set({
                                              'ordersCounterField':
                                                  FieldValue.increment(1)
                                            }, SetOptions(merge: true));
                                            cart.forEach((element) {
                                              if (element.product
                                                          .quantityInSupply !=
                                                      null &&
                                                  element.product
                                                          .quantityInSupply >=
                                                      element
                                                          .product.quantity) {
                                                FirebaseFirestore.instance
                                                    .collection('products')
                                                    .doc(element.product
                                                        .productDocumentId)
                                                    .update({
                                                  'quantityInSupply':
                                                      FieldValue.increment(
                                                          -element
                                                              .product.quantity)
                                                });
                                              }

                                              FirebaseFirestore.instance
                                                  .collection('cart')
                                                  .doc(element.documentId)
                                                  .delete();
                                            });
                                            o.documentId = value.id;
                                            if (paymentMethod ==
                                                PaymentMethods.CreditCard) {
                                              var res = await http.post(
                                                  '${viewModel.prefs.getString('ServerBaseAddress')}Api/Orders/CheckoutFlutter',
                                                  body: jsonEncode(o.toCheckoutJson(context)),
                                                  headers: {
                                                    'Content-Type':
                                                        'application/json'
                                                  });
                                              if (res.statusCode == 200) {
                                                var decoded =
                                                    jsonDecode(res.body)
                                                        as Map<String, dynamic>;
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            UnipayCheckoutPage(
                                                              order: o,
                                                              createOrderResult:
                                                                  decoded,
                                                            )));
                                              }
                                            }
                                            showDialog(
                                              context: context,
                                              builder: (context) => OkDialog(
                                                content: AppLocalizations.of(
                                                        context)
                                                    .translate('Order made'),
                                                title: AppLocalizations.of(
                                                        context)
                                                    .translate('Information'),
                                              ),
                                            );
                                            AudioCache()
                                                .play('OrderRecieved.mp3');
                                          } on MessageException catch (me) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => OkDialog(
                                                title:
                                                    AppLocalizations.of(context)
                                                        .translate('Error'),
                                                content: me.message,
                                              ),
                                            );
                                          } catch (e) {} finally {
                                            ordering.value = false;
                                          }
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .translate('Place order'),
                                          style: TextStyle(color: kIcons),
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
                )
              : Align(
                  child: Text(
                      AppLocalizations.of(context).translate('Unauthorized')),
                );
        },
      ),
    );
  }
}

class CartItemWidget extends StatefulWidget {
  final Function cartItemChanged;
  const CartItemWidget({
    this.cartItemChanged,
    @required this.p,
  });

  final CartItem p;

  @override
  _CartItemWidgetState createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: EdgeInsets.only(top: 8, left: 8),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 140,
                width: 160,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: safeNetworkImage(widget.p?.product?.images
                          ?.firstWhere((element) => true, orElse: () => null)
                          ?.downloadUrl),
                    )),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 12, top: 12),
                  child: ValueListenableBuilder<DatabaseUser>(
                      builder: (context, user, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                                getLocalizedName(
                                    widget.p.product.localizedName, context),
                                style: kProductNameTextStyle),
                            ...?widget.p.product.addonDescriptions.map((e) =>
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Flexible(
                                      child: Text(
                                          '${getLocalizedName(e.localizedAddonDescriptionName, context)}',
                                          style: kDescriptionHeaderTextStyle),
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
                            ...?widget.p.product.checkableAddons
                                ?.map((e) => Row(
                                      children: [
                                        Radio(
                                          activeColor: kPrimary,
                                          value: e,
                                          groupValue: widget
                                              ?.p?.product?.checkableAddons
                                              ?.firstWhere(
                                                  (element) =>
                                                      element.isSelected,
                                                  orElse: () => null),
                                          onChanged: (val) {
                                            widget.p.product.checkableAddons
                                                .forEach((element) {
                                              element.isSelected = false;
                                            });
                                            (val as PaidAddon).isSelected =
                                                true;
                                            widget.cartItemChanged?.call();
                                          },
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                getLocalizedName(
                                                    e.localizedName, context),
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12.0,
                                                ),
                                              ),
                                              if ((e.price ?? 0) > 0)
                                                Text(
                                                  '+${e.price.toString()}₾',
                                                  style: TextStyle(
                                                    fontFamily: 'Sans',
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ))
                                ?.toList(),
                            SizedBox(
                              height: 4,
                            ),
                            ...?widget.p.product.selectableAddons
                                ?.map((e) => Stack(
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              activeColor: kPrimary,
                                              value: e.isSelected,
                                              onChanged: (val) {
                                                e.isSelected = val;
                                                widget.cartItemChanged?.call();
                                              },
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                    getLocalizedName(
                                                        e.localizedName,
                                                        context),
                                                    style:
                                                        kDescriptionTextStyle),
                                                if (e.price != null)
                                                  Text(
                                                    '+${e.price?.toString() ?? ''}₾',
                                                    style: TextStyle(
                                                      fontFamily: 'Sans',
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                              getLocalizedName(
                                  widget.p.product.localizedDescription,
                                  context),
                              style: kDescriptionTextStyle,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '₾${widget.p.product.totalProductPrice?.toString() ?? '0'}',
                                style: kPriceTextStyle,
                              ),
                            ),
                            if (user?.role == UserType.user) child,
                          ],
                        );
                      },
                      valueListenable: viewModel.databaseUser,
                      child: CartControl(
                        product: widget.p.product,
                      )), //
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
