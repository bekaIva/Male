import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/singup_loginPage.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, mainViewmodel, child) {
        return Drawer(
          child: ListView(
            children: <Widget>[
              Consumer<User>(
                builder: (context, user, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: mainViewmodel.isSigningSignUping,
                    builder: (context, value, child) {
                      return DrawerHeader(
                        decoration: BoxDecoration(color: kPrimary),
                        child: Stack(
                          children: <Widget>[
                            Center(
                              child: Text(
                                user == null
                                    ? AppLocalizations.of(context)
                                        .translate('Unauthorized')
                                    : user.isAnonymous
                                        ? AppLocalizations.of(context)
                                            .translate('Guest')
                                        : (user.displayName?.length ?? 0) > 0
                                            ? user.displayName
                                            : user.email,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 22),
                              ),
                            ),
                            value
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Container()
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              Consumer<User>(
                builder: (context, user, child) {
                  if (user == null) {
                    return ListTile(
                      leading: Icon(FontAwesome.sign_out),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SingUpLoginPage(
                              login: true,
                            ),
                          ),
                        );
                      },
                      title: Text(
                          AppLocalizations.of(context).translate('Sign in')),
                    );
                  } else {
                    return ListTile(
                      leading: Icon(FontAwesome.sign_out),
                      onTap: () {
                        mainViewmodel.auth.signOut();
                      },
                      title: Text(
                          AppLocalizations.of(context).translate('Sign out')),
                    );
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }
}
