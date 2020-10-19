import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/ChatMessage.dart';
import 'package:male/Models/User.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/UserPage.dart';
import 'package:provider/provider.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).translate('Users')),
          ),
          body: ValueListenableBuilder(
            valueListenable: viewModel.users,
            builder: (context, value, child) {
              viewModel.users.value.sort((user1, user2) {
                var max1 = user1.messages.value.fold<ChatMessage>(null,
                    (previousValue, element) {
                  if (previousValue == null)
                    return element;
                  else {
                    if (((previousValue?.serverTime as Timestamp ??
                                    Timestamp.fromMillisecondsSinceEpoch(0))
                                ?.compareTo(element?.serverTime as Timestamp ??
                                    Timestamp.fromMillisecondsSinceEpoch(0)) ??
                            0) >
                        0) {
                      return previousValue;
                    } else {
                      return element;
                    }
                  }
                });

                var max2 = user2.messages.value.fold<ChatMessage>(null,
                    (previousValue, element) {
                  if (previousValue == null)
                    return element;
                  else {
                    if (((previousValue?.serverTime as Timestamp ??
                                    Timestamp.fromMillisecondsSinceEpoch(0))
                                ?.compareTo(element?.serverTime as Timestamp ??
                                    Timestamp.fromMillisecondsSinceEpoch(0)) ??
                            0) >
                        0) {
                      return previousValue;
                    } else {
                      return element;
                    }
                  }
                });

                return ((max2?.serverTime as Timestamp ??
                            Timestamp.fromMillisecondsSinceEpoch(0))
                        ?.compareTo(max1?.serverTime as Timestamp ??
                            Timestamp.fromMillisecondsSinceEpoch(0)) ??
                    -1);
              });
              return ListView.builder(
                itemCount: viewModel.users.value.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: UserWidget(
                      user: viewModel.users.value[index],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class UserWidget extends StatelessWidget {
  final DatabaseUser user;
  UserWidget({this.user});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (user.hasNewMessages.value) {
          user.hasNewMessages.value = false;
          FirebaseFirestore.instance
              .collection('/newmessages')
              .doc('toAdminFrom${user.uid}')
              .set({'hasNewMessages': false});
        }
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserPage(
                user: user,
              ),
            ));
      },
      leading: (user.photoUrl?.length ?? 0) > 0
          ? CircleAvatar(
              backgroundImage: NetworkImage(user.photoUrl),
            )
          : Icon(FontAwesome.user),
      title: ValueListenableBuilder<bool>(
        valueListenable: user.hasNewMessages,
        builder: (context, value, child) {
          return Row(
            children: <Widget>[
              Text(user.isAnonymous
                  ? AppLocalizations.of(context).translate('Guest')
                  : (user.displayName?.length ?? 0) > 0
                      ? user.displayName
                      : user.email),
              SizedBox(
                width: 10,
              ),
              if (value ?? false)
                Icon(
                  Icons.message,
                  color: kPrimary,
                )
            ],
          );
        },
      ),
    );
  }
}
