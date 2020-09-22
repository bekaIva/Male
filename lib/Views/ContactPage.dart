import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/ChatMessage.dart';
import 'package:male/Models/User.dart';
import 'package:male/Models/enums.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

class MessageWidget extends StatelessWidget {
  DatabaseUser currentUser;
  final ChatMessage message;
  MessageWidget({this.message, this.currentUser});
  @override
  Widget build(BuildContext context) {
    bool isMe = false;

    if (currentUser.role == UserType.admin &&
        message.userType == UserType.admin)
      isMe = true;
    else
      isMe = currentUser.uid == message.senderUserId;

    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.userDisplayName,
            style: TextStyle(color: Colors.black54),
          ),
          Text(
            DateFormat.yMd().add_Hms().format(
                (message.serverTime as Timestamp)?.toDate() ?? DateTime(0000)),
            style: TextStyle(color: Colors.black54),
          ),
          Material(
            elevation: 4,
            color: isMe ? kPrimary : Colors.white,
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
                topRight: Radius.circular(isMe ? 0 : 30),
                topLeft: Radius.circular(isMe ? 30 : 0)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                message.message,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  TextEditingController sendMessageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(milliseconds: 100)).then((value) {
      try {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      } catch (e) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MainViewModel, User>(
      builder: (context, viewModel, firebaseUser, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).translate('Contact us')),
          ),
          body: firebaseUser != null
              ? ValueListenableBuilder<DatabaseUser>(
                  valueListenable: viewModel.databaseUser,
                  builder: (context, value, child) {
                    if (value?.role == null) {
                      return Text('Please authorize');
                    }
                    switch (value.role) {
                      case UserType.user:
                        {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: viewModel.userMessages,
                                    builder: (context, value, child) {
                                      return ListView.builder(
                                        controller: scrollController,
                                        itemCount:
                                            viewModel.userMessages.value.length,
                                        itemBuilder: (context, index) {
                                          viewModel.newMessages.value = false;
                                          return MessageWidget(
                                              currentUser:
                                                  viewModel.databaseUser.value,
                                              message: viewModel
                                                  .userMessages.value[index]);
                                        },
                                      );
                                    },
                                  ),
                                ),
                                TextField(
                                  cursorColor: kPrimary,
                                  controller: sendMessageController,
                                  decoration: InputDecoration(
                                      focusedBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: kPrimary)),
                                      enabledBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: kPrimary)),
                                      disabledBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: kPrimary)),
                                      suffixIcon: Material(
                                        child: InkWell(
                                          onTap: () {
                                            if (!((sendMessageController
                                                        ?.text?.length ??
                                                    0) >
                                                0)) return;
                                            FirebaseFirestore.instance
                                                .collection('/messages')
                                                .doc()
                                                .set(ChatMessage(
                                                        userType: UserType.user,
//                                            widget.user.displayName ?? widget.user.isAnonymous
//                                                ? AppLocalizations.of(context).translate('Guest')
//                                                : widget.user.email ??
//                                                AppLocalizations.of(context).translate('Unknown User')
                                                        userDisplayName: viewModel
                                                                .user
                                                                .displayName ??
                                                            (viewModel.user
                                                                    .isAnonymous
                                                                ? AppLocalizations.of(context)
                                                                    .translate(
                                                                        'Guest')
                                                                : viewModel.user
                                                                        .email ??
                                                                    AppLocalizations.of(context)
                                                                        .translate(
                                                                            'Unknown User')),
                                                        serverTime: FieldValue
                                                            .serverTimestamp(),
                                                        pair:
                                                            'admin${firebaseUser.uid}',
                                                        message:
                                                            sendMessageController
                                                                .value.text,
                                                        senderUserId:
                                                            firebaseUser.uid,
                                                        targetUserId: 'admin')
                                                    .toJson());
                                            FirebaseFirestore.instance
                                                .collection('/newmessages')
                                                .doc(
                                                    'toAdminFrom${firebaseUser.uid}')
                                                .set({
                                              'hasNewMessages': true
                                            }).catchError((err) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => OkDialog(
                                                  title: AppLocalizations.of(
                                                          context)
                                                      .translate('Error'),
                                                  content: err.toString(),
                                                ),
                                              );
                                            });
                                            sendMessageController.clear();
                                            scrollController.jumpTo(
                                                scrollController
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
                          );
                        }
                      case UserType.admin:
                        {
                          return (Container());
                        }
                      default:
                        {
                          return Container();
                        }
                    }
                  },
                )
              : Container(child: Text("Please authorize")),
        );
      },
    );
  }
}
