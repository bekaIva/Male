import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:male/Views/ProductPage.dart';
import 'package:male/Views/singup_loginPage.dart';
import 'package:provider/provider.dart';

import 'Localizations/app_localizations.dart';
import 'ViewModels/LanguageSettings.dart';
import 'Views/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaleApp());
}

class MaleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (c) => LanguageSettings(),
        ),
        ChangeNotifierProvider(
          create: (c) => MainViewModel(),
        ),
        StreamProvider<User>.value(
          value: FirebaseAuth.instance.authStateChanges(),
        )
      ],
      child: Consumer<LanguageSettings>(
        builder: (context, setting, child) => MaterialApp(
          initialRoute: HomePage.id,
          locale: setting.userLocale.value,
          routes: {
            HomePage.id: (context) => HomePage(),
            ProductPage.id: (context) => ProductPage(),
            SingUpLoginPage.id: (context) => SingUpLoginPage()
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (setting.userLocale.value != null)
              return setting.userLocale.value;
            for (var supportedLocale in supportedLocales) {
              print(supportedLocale.toLanguageTag());
              if (supportedLocale.languageCode == locale.languageCode &&
                  supportedLocale.countryCode == locale.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          title: 'Male',
          theme: ThemeData(
            buttonTheme: ButtonThemeData(
              buttonColor: kPrimary,
              textTheme: ButtonTextTheme.normal,
              colorScheme:
                  Theme.of(context).colorScheme.copyWith(primary: kPrimary),
            ),
            appBarTheme: AppBarTheme(color: kPrimary),
            primarySwatch: Colors.blue,
            primaryColor: kPrimary,
            accentColor: kPrimary,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: GoogleFonts.muktaVaaniTextTheme(),
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
