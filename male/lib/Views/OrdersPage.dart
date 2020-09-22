import 'package:audioplayers/audio_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Order.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/OrderDetailPage.dart';
import 'package:male/Widgets/FadeInWidget.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
        child: Consumer2<MainViewModel, User>(
      builder: (context, viewModel, user, child) => user == null
          ? Align(
              alignment: Alignment.center,
              child:
                  Text(AppLocalizations.of(context).translate('Unauthorized')),
            )
          : ValueListenableBuilder<DatabaseUser>(
              valueListenable: viewModel.databaseUser,
              builder: (context, databaseUser, child) => databaseUser != null
                  ? StreamBuilder<QuerySnapshot>(
                      stream: databaseUser.role == UserType.admin
                          ? FirebaseFirestore.instance
                              .collection('orders')
                              .orderBy('serverTime', descending: true)
                              .snapshots()
                          : FirebaseFirestore.instance
                              .collection('orders')
                              .where('uid', isEqualTo: user.uid)
                              .orderBy('serverTime', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(kPrimary),
                            ),
                          );
                        if (snapshot.data != null) {
                          if (snapshot.data.docs.length == 0)
                            return Stack(
                              children: [
                                Container(
                                    constraints: BoxConstraints.expand(),
                                    child: SvgPicture.asset(
                                        'assets/svg/NoItem.svg')),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(context).size.height /
                                              4),
                                  child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .translate('You have nothing here'),
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
                          bool newOrders = false;
                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: snapshot.data.docs.length,
                            itemBuilder: (context, index) {
                              var order = Order.fromJson(
                                  snapshot.data.docs[index].data());
                              if (!order.isSeen) newOrders = true;

                              if (index == snapshot.data.docs.length - 1 &&
                                  databaseUser.role == UserType.admin &&
                                  newOrders)
                                AudioCache().play('OrderRecieved.mp3');

                              order.documentId = snapshot.data.docs[index].id;
                              return Slidable(
                                actionPane: SlidableDrawerActionPane(),
                                actions: [
                                  if (databaseUser?.role == UserType.user)
                                    SlideAction(
                                        onTap: () async {
                                          await Future.forEach(order.products,
                                              (element) async {
                                            try {
                                              var res = await FirebaseFirestore
                                                  .instance
                                                  .collection('products')
                                                  .doc(
                                                      element.productDocumentId)
                                                  .get();
                                              if (res.exists) {
                                                var p = Product.fromJson(
                                                    res.data());
                                                p.productDocumentId = res.id;
                                                await viewModel
                                                    .storeCart(element);
                                              }
                                            } catch (e) {
                                              print(e.toString());
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: SlideActionElement(
                                            iconData: Icons.repeat,
                                            text: AppLocalizations.of(context)
                                                .translate('Repeat in cart'),
                                            color: kPrimary,
                                          ),
                                        ))
                                ],
                                secondaryActions: [
                                  if (databaseUser?.role == UserType.admin)
                                    SlideAction(
                                        onTap: () {
                                          order.products.forEach((element) {
                                            if (element.quantityInSupply !=
                                                    null &&
                                                order
                                                        .deliveryStatusSteps[
                                                            DeliveryStatus
                                                                .Completed]
                                                        .isActive ==
                                                    false) {
                                              FirebaseFirestore.instance
                                                  .collection('products')
                                                  .doc(
                                                      element.productDocumentId)
                                                  .update({
                                                'quantityInSupply':
                                                    FieldValue.increment(
                                                        element.quantity)
                                              });
                                            }
                                          });
                                          FirebaseFirestore.instance
                                              .collection('orders')
                                              .doc(order.documentId)
                                              .delete();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SlideActionElement(
                                            iconData: Icons.delete,
                                            color: Colors.red,
                                            text: AppLocalizations.of(context)
                                                .translate('Delete'),
                                          ),
                                        ))
                                ],
                                child: OrderWidget(
                                  showIsSeenIcon:
                                      databaseUser.role == UserType.admin
                                          ? true
                                          : false,
                                  order: order,
                                ),
                              );
                            },
                          );
                        } else
                          return Align(
                              alignment: Alignment.center,
                              child: Text('No Data'));
                      },
                    )
                  : Center(
                      child: Text(AppLocalizations.of(context)
                          .translate('Unauthorized')),
                    ),
            ),
    ));
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
                          '${AppLocalizations.of(context).translate('Order price')}: ₾${(order.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1)))?.toString() ?? '0'}',
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
                                    EnumToString.parse(order
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
