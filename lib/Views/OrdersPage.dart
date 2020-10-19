import 'package:audioplayers/audio_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Order.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/UserPage.dart';
import 'package:male/Widgets/FadeInWidget.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<DateTime> pickedTime;
  @override
  Widget build(BuildContext context) {
    return FadeInWidget(child: Consumer2<MainViewModel, User>(
      builder: (context, viewModel, user, child) {
        viewModel.orderTimePicked = (picked) {
          setState(() {
            pickedTime = picked;
          });
        };
        return user == null
            ? Align(
                alignment: Alignment.center,
                child: Text(
                    AppLocalizations.of(context).translate('Unauthorized')),
              )
            : ValueListenableBuilder<DatabaseUser>(
                valueListenable: viewModel.databaseUser,
                builder: (context, databaseUser, child) => databaseUser != null
                    ? StreamBuilder<List<Order>>(
                        stream: databaseUser.role == UserType.admin
                            ? FirebaseFirestore.instance
                                .collection('orders')
                                .orderBy('serverTime', descending: true)
                                .snapshots()
                                .map<List<Order>>(
                                    (event) => event.docs.map((e) {
print('aaaa');
                                          var order = Order.fromJson(e.data());
                                          print(order.toString());
                                          order.documentId = e.id;
                                          return order;
                                        }).toList())
                            : FirebaseFirestore.instance
                                .collection('orders')
                                .where('uid', isEqualTo: user.uid)
                                .orderBy('serverTime', descending: true)
                                .snapshots()
                                .map<List<Order>>(
                                    (event) => event.docs.map((e) {
                                          var order = Order.fromJson(e.data());
                                          order.documentId = e.id;
                                          return order;
                                        }).toList()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(kPrimary),
                              ),
                            );
                          List<Order> filteredOrders;
                          if (pickedTime?.length == 2) {
                            var startTime = pickedTime[0];
                            var endTime = pickedTime[1];
                            filteredOrders = snapshot.data.where((element) {
                              return ((element.serverTime as Timestamp)
                                          .toDate()
                                          .isAfter(startTime) ||
                                      (element.serverTime as Timestamp)
                                          .toDate()
                                          .isAtSameMomentAs(startTime)) &&
                                  ((element.serverTime as Timestamp)
                                          .toDate()
                                          .isBefore(endTime) ||
                                      (element.serverTime as Timestamp)
                                          .toDate()
                                          .isAtSameMomentAs(endTime));
                            }).toList();
                          } else {
                            filteredOrders = snapshot.data;
                          }

                          if (filteredOrders != null) {
                            if (filteredOrders.length == 0)
                              return YouHaveNothingWidgets();
                            bool newOrders = false;
                            return ListView.builder(
                              physics: BouncingScrollPhysics(),
                              itemCount: filteredOrders.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0)
                                  return OrdersSummaryWidget(
                                    child: databaseUser.role == UserType.admin
                                        ? ValueListenableBuilder<
                                            List<DatabaseUser>>(
                                            valueListenable: viewModel.users,
                                            builder: (context, users, child) {
                                              Map<DatabaseUser, List<Order>>
                                                  usersByOrder = {};
                                              users.forEach((element) {
                                                var orders = filteredOrders
                                                    .where((order) =>
                                                        order
                                                            .deliveryStatusSteps[
                                                                DeliveryStatus
                                                                    .Completed]
                                                            .isActive &&
                                                        element.uid ==
                                                            order.uid)
                                                    .toList();
                                                if (orders.length > 0)
                                                  usersByOrder[element] =
                                                      orders;
                                              });
                                              var sortedUsersByOrderEntities =
                                                  usersByOrder.entries.toList()
                                                    ..sort((a, b) =>
                                                        (b.value.length -
                                                            a.value.length))
                                                    ..takeWhile((value) =>
                                                        (value?.value?.length ??
                                                            0) >
                                                        0);
                                              if (sortedUsersByOrderEntities
                                                      .length >
                                                  10)
                                                sortedUsersByOrderEntities =
                                                    sortedUsersByOrderEntities
                                                        .take(10)
                                                        .toList();
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(AppLocalizations.of(
                                                          context)
                                                      .translate(
                                                          'Orders by users')),
                                                  SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: DataTable(
                                                      columns: [
                                                        DataColumn(
                                                            label: Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'Users'))),
                                                        DataColumn(
                                                            label: Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'Completed orders'))),
                                                        DataColumn(
                                                            label: Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'Total paid')))
                                                      ],
                                                      rows:
                                                          sortedUsersByOrderEntities
                                                              .map((e) =>
                                                                  DataRow(
                                                                      cells: [
                                                                        DataCell(
                                                                            Text(e.key.displayName ??
                                                                                (e.key.email ?? e.key.isAnonymous ? AppLocalizations.of(context).translate('Guest') : AppLocalizations.of(context).translate('Unknown'))),
                                                                            onTap:
                                                                                () {
                                                                          Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => UserPage(
                                                                                  user: e.key,
                                                                                ),
                                                                              ));
                                                                        }),
                                                                        DataCell(Text(e
                                                                            .value
                                                                            .length
                                                                            .toString())),
                                                                        DataCell(
                                                                            Text('${e.value?.fold<double>(0, (previousValue, element) => previousValue + (element.products.fold<double>(0, (previousValue, element) => previousValue + element.totalProductPrice * (element.quantity ?? 1))) + element.deliveryFee)?.toStringAsFixed(2) ?? 0}₾'))
                                                                      ]))
                                                              .toList(),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          )
                                        : null,
                                    orders: filteredOrders,
                                  );
                                var order = filteredOrders[index - 1];
                                if (!order.isSeen) newOrders = true;

                                if (index == filteredOrders.length &&
                                    databaseUser.role == UserType.admin &&
                                    newOrders)
                                  AudioCache().play('OrderRecieved.mp3');

                                return Slidable(
                                  actionPane: SlidableDrawerActionPane(),
                                  actions: [
                                    if (databaseUser?.role == UserType.user)
                                      SlideAction(
                                          onTap: () async {
                                            await Future.forEach(order.products,
                                                (element) async {
                                              try {
                                                var res =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('products')
                                                        .doc(element
                                                            .productDocumentId)
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
                                          onTap: () async {
                                            var res = await showDialog<String>(
                                              context: context,
                                              builder: (context) => OkDialog(
                                                  content:
                                                      '${AppLocalizations.of(context).translate('Are you sure you want to delete the order?')} \n${AppLocalizations.of(context).translate('Order')}: ${order.orderId}',
                                                  title: AppLocalizations.of(
                                                          context)
                                                      .translate(
                                                          'Delete order')),
                                            );
                                            if (res == 'Ok') {
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
                                                      .doc(element
                                                          .productDocumentId)
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
                                            }
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
                            return YouHaveNothingWidgets();
                        },
                      )
                    : Center(
                        child: Text(AppLocalizations.of(context)
                            .translate('Unauthorized')),
                      ),
              );
      },
    ));
  }
}
