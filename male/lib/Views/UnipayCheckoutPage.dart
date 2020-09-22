import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Order.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UnipayCheckoutPage extends StatelessWidget {
  final Order order;
  final Map<String, dynamic> createOrderResult;
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  UnipayCheckoutPage({this.createOrderResult, this.order});
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('Checkout')),
        ),
        body: Container(
            child: ValueListenableBuilder<bool>(
          valueListenable: loading,
          child: WebView(
            onPageStarted: (val) {
              loading.value = true;
            },
            onPageFinished: (val) {
              loading.value = false;
            },
            navigationDelegate: (req) async {
              if (req.url.contains('CheckoutResult?MerchantOrderID')) {
                try {
                  FirebaseFirestore.instance
                      .collection('/orders')
                      .doc(order.documentId)
                      .get()
                      .then((value) async {
                    if (value.data != null) {
                      Order o = Order.fromJson(value.data());
                      o.documentId = value.id;
                      var res = await http.post(
                          '${viewModel.prefs.getString('ServerBaseAddress')}CheckoutResult',
                          body: jsonEncode(o.toCheckoutJson(context)),
                          headers: {'Content-Type': 'application/json'});
                      print(res.body);
                    }
                  });
                } catch (e) {
                  print(e);
                }

                Navigator.pop(context);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            javascriptMode: JavascriptMode.unrestricted,
            initialUrl: createOrderResult['data']['checkout'] as String,
          ),
          builder: (context, value, child) => Stack(
            children: [
              child,
              if (value)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(kPrimary),
                  ),
                )
            ],
          ),
        )),
      ),
    );
  }
}
