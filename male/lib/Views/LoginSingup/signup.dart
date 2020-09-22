import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/HomePage.dart';
import 'package:male/Widgets/Widgets.dart';
import 'package:provider/provider.dart';

class SignUp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (_, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context).translate('Sign up with'),
              style: TextStyle(
                fontSize: 16,
                color: kPrimary,
                height: 2,
              ),
            ),
            Text(
              AppLocalizations.of(context).translate('App Name'),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: kPrimary,
                letterSpacing: 2,
                height: 1,
              ),
            ),
            SizedBox(
              height: 16,
            ),
            TextField(
              controller: viewModel.emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: kPrimary),
              decoration: InputDecoration(
                hintText:
                    AppLocalizations.of(context).translate('Email / Username'),
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: kPrimary.withOpacity(.8),
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(width: 1, color: kPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(width: 1, color: kPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(width: 1, color: kPrimary),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
            SizedBox(
              height: 16,
            ),
            TextField(
              controller: viewModel.passwordController,
              obscureText: true,
              style: TextStyle(color: kPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).translate('Password'),
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: kPrimary.withOpacity(.8),
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(width: 1, color: kPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(width: 1, color: kPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(width: 1, color: kPrimary),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
            SizedBox(
              height: 24,
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFF3D657).withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: FlatButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                onPressed: () async {
                  try {
                    viewModel.isSigningSignUping.value = true;
                    var res = await viewModel.signUpWithEmailAndPassword();
                    if (!res) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return OkDialog(
                                title: AppLocalizations.of(context)
                                    .translate('Error'),
                                content: AppLocalizations.of(context)
                                    .translate('Registration failed'));
                          });
                    } else {
                      Navigator.of(context).pushNamed(HomePage.id);
                    }
                  } on PlatformException catch (pe) {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return OkDialog(
                              title: AppLocalizations.of(context)
                                  .translate('Error'),
                              content: pe.message);
                        });
                  } catch (e) {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return OkDialog(
                            title:
                                AppLocalizations.of(context).translate('Error'),
                            content:
                                '${AppLocalizations.of(context).translate('Registration failed')}: ${AppLocalizations.of(context).translate('Unknown error')}',
                          );
                        });
                  } finally {
                    viewModel.isSigningSignUping.value = false;
                  }
                },
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('SIGN UP'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kIcons,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 24,
            ),
            // Text(
            //   AppLocalizations.of(context).translate('Or Signup with'),
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 16,
            //     color: kPrimary,
            //     height: 1,
            //   ),
            // ),
            // SizedBox(
            //   height: 16,
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: <Widget>[
            //     RawMaterialButton(
            //       constraints: BoxConstraints(minWidth: 2),
            //       padding: EdgeInsets.all(0),
            //       onPressed: () {},
            //       shape: CircleBorder(),
            //       child: Icon(
            //         Entypo.facebook_with_circle,
            //         size: 32,
            //         color: kPrimary,
            //       ),
            //     ),
            //     SizedBox(
            //       width: 24,
            //     ),
            //     RawMaterialButton(
            //       constraints: BoxConstraints(minWidth: 2),
            //       shape: CircleBorder(),
            //       onPressed: () {},
            //       child: Icon(
            //         Entypo.google__with_circle,
            //         size: 32,
            //         color: kPrimary,
            //       ),
            //     ),
            //   ],
            // )
          ],
        );
      },
    );
  }
}
