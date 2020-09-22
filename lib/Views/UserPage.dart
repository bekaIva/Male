import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Address.dart';
import 'package:male/Models/ChatMessage.dart';
import 'package:male/Models/Order.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Widgets/AddressesList.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ContactPage.dart';
import 'OrdersPage.dart';

class UserPage extends StatefulWidget {
  final DatabaseUser user;
  UserPage({this.user});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  ScrollController scrollController = ScrollController();
  TextEditingController sendMessageController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.user.displayName ??
                  (widget.user.isAnonymous
                      ? AppLocalizations.of(context).translate('Guest')
                      : widget.user.email ??
                          AppLocalizations.of(context)
                              .translate('Unknown User'))),
              bottom: TabBar(
                indicatorColor: Colors.white,
                tabs: <Widget>[
                  Tab(
                    text: AppLocalizations.of(context).translate('Contact'),
                  ),
                  Tab(
                    text: AppLocalizations.of(context).translate('Profile'),
                  ),
                  Tab(
                    text: AppLocalizations.of(context).translate('Orders'),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, bottom: 24.0),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: widget.user.messages,
                          builder: (context, value, child) {
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: widget.user.messages.value.length,
                              itemBuilder: (context, index) {
                                return MessageWidget(
                                    currentUser: viewModel.databaseUser.value,
                                    message: widget.user.messages.value[index]);
                              },
                            );
                          },
                        ),
                      ),
                      TextField(
                        controller: sendMessageController,
                        decoration: InputDecoration(
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: kPrimary)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: kPrimary)),
                            disabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: kPrimary)),
                            suffixIcon: Material(
                              child: InkWell(
                                onTap: () {
                                  if (!((sendMessageController?.text?.length ??
                                          0) >
                                      0)) return;
                                  FirebaseFirestore.instance
                                      .collection('/messages')
                                      .doc()
                                      .set(ChatMessage(
                                              userType: viewModel
                                                  .databaseUser.value.role,
                                              userDisplayName: viewModel
                                                      .user.displayName ??
                                                  (viewModel.user.isAnonymous
                                                      ? AppLocalizations.of(
                                                              context)
                                                          .translate('Guest')
                                                      : viewModel.user.email ??
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'Unknown User')),
                                              serverTime:
                                                  FieldValue.serverTimestamp(),
                                              pair: 'admin${widget.user.uid}',
                                              message: sendMessageController
                                                  .value.text,
                                              senderUserId: viewModel.user.uid,
                                              targetUserId: widget.user.uid)
                                          .toJson());
                                  FirebaseFirestore.instance
                                      .collection('/newmessages')
                                      .doc('to${widget.user.uid}FromAdmin')
                                      .set({'hasNewMessages': true}).catchError(
                                          (err) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => OkDialog(
                                        title: AppLocalizations.of(context)
                                            .translate('Error'),
                                        content: err.toString(),
                                      ),
                                    );
                                  });
                                  sendMessageController.clear();
                                  scrollController.jumpTo(scrollController
                                      .position.maxScrollExtent);
                                },
                                child: Icon(
                                  Icons.send,
                                  color: kPrimary,
                                ),
                              ),
                            )),
                      )
                    ],
                  ),
                ),
                UserProfilePage(
                  user: widget.user,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('uid', isEqualTo: widget.user.uid)
                      .orderBy('serverTime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(kPrimary),
                          ),
                        );
                      if (snapshot.data == null) return Text('No Data');

                      if (snapshot.data.docs.length == 0)
                        return Stack(
                          children: [
                            Container(
                                constraints: BoxConstraints.expand(),
                                child:
                                    SvgPicture.asset('assets/svg/NoItem.svg')),
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).size.height / 4),
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
                                              color:
                                                  Colors.white.withOpacity(1),
                                              blurRadius: 10.0,
                                              spreadRadius: 2.0)
                                        ]),
                                  )),
                            )
                          ],
                        );
                      return ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          var order =
                              Order.fromJson(snapshot.data.docs[index].data());
                          order.documentId = snapshot.data.docs[index].id;
                          return OrderWidget(
                            order: order,
                          );
                        },
                      );
                    } else
                      return Align(
                          alignment: Alignment.center, child: Text('No Data'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final DatabaseUser user;
  UserProfilePage({this.user});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('/users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(kPrimary),
              ),
            );
          if (snapshot.data == null)
            return Center(
              child: Text('No data'),
            );
          var streamUser = DatabaseUser.fromMap(snapshot.data.data());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              (streamUser?.photoUrl?.length ?? 0) > 0
                  ? Container(
                      width: 100,
                      height: MediaQuery.of(context).size.height / 4,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(streamUser.photoUrl))),
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  Colors.black54,
                                  Colors.black54,
                                  Colors.transparent
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: [0, .15, .5])),
                        child: Container(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  streamUser.displayName ??
                                      (streamUser.isAnonymous
                                          ? AppLocalizations.of(context)
                                              .translate('Guest')
                                          : ''),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kIcons,
                                      fontSize: 24),
                                ),
                                Text(
                                  streamUser.email ?? '',
                                  style: TextStyle(color: kIcons),
                                ),
                              ],
                            )),
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          FontAwesome.user,
                          color: Colors.grey.shade600,
                          size: 60,
                        ),
                        Text(streamUser.displayName ??
                            (streamUser.isAnonymous
                                ? AppLocalizations.of(context)
                                    .translate('Guest')
                                : '')),
                      ],
                    ),
              Divider(
                height: 30,
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('User info'),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(AppLocalizations.of(context)
                                      .translate('User type')),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Switch(
                                        activeColor: kPrimary,
                                        onChanged: (val) {
                                          FirebaseFirestore.instance
                                              .collection('/users')
                                              .doc(streamUser.uid)
                                              .update({
                                            'role': EnumToString.parse(val
                                                ? UserType.admin
                                                : UserType.user)
                                          });
                                        },
                                        value: streamUser.role == UserType.admin
                                            ? true
                                            : false,
                                      ),
                                      Text(AppLocalizations.of(context)
                                          .translate(EnumToString.parse(
                                              streamUser.role))),
                                    ],
                                  )
                                ],
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(AppLocalizations.of(context)
                                      .translate('User name')),
                                  Text(streamUser.displayName ??
                                      (streamUser.isAnonymous
                                          ? AppLocalizations.of(context)
                                              .translate('Guest')
                                          : '')),
                                ],
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(AppLocalizations.of(context)
                                      .translate('E-mail')),
                                  Text(streamUser.email ?? ''),
                                ],
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(AppLocalizations.of(context)
                                      .translate('Phone')),
                                  SelectableText(
                                    streamUser.phoneNumber ?? '',
                                    onTap: () async {
                                      if (await canLaunch(
                                          'tel:${streamUser.phoneNumber ?? ''}')) {
                                        launch(
                                            'tel:${streamUser.phoneNumber ?? ''}');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          FontAwesome.address_card,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('User addresses'),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('/userAddresses')
                                    .where('uid', isEqualTo: streamUser.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    return Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation(kPrimary),
                                      ),
                                    );
                                  if (snapshot.data == null) return Container();
                                  var addresses = snapshot.data.docs?.map((e) {
                                    var a = UserAddress.fromJson(e.data());
                                    a.referance = e.reference;
                                    return a;
                                  })?.toList();

                                  return addresses != null
                                      ? AddressesList(
                                          isReadOnly: true,
                                          userAddresses: addresses,
                                        )
                                      : Container();
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
