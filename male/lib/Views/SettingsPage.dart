import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Settings.dart';
import 'package:male/ViewModels/MainViewModel.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double maximumOrderPrice;
  double minimumOrderPrice;
  double deliveryFeeUnderMaximumOrderPrice;
  TextEditingController maximumOrderPriceController = TextEditingController();
  TextEditingController minimumOrderPriceController = TextEditingController();
  TextEditingController deliveryFeeUnderMaximumOrderPriceController =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('Settings')),
      ),
      body: Consumer<MainViewModel>(
        builder: (context, viewModel, child) {
          AppSettings settings = viewModel.settings.value;
          deliveryFeeUnderMaximumOrderPriceController.text =
              settings.deliveryFeeUnderMaximumOrderPrice?.toString();
          maximumOrderPriceController.text =
              settings.maximumOrderPrice?.toString();
          minimumOrderPriceController.text =
              settings.minimumOrderPrice?.toString();
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(AppLocalizations.of(context).translate('General')),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.do_not_disturb,
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(AppLocalizations.of(context)
                            .translate('Stop ordering')),
                      ],
                    ),
                    Switch(
                      value: settings.stopOrdering ?? false,
                      activeColor: kPrimary,
                      onChanged: (value) {
                        setState(() {
                          settings.stopOrdering = value;
                        });
                        FirebaseFirestore.instance
                            .collection('/settings')
                            .doc('settings')
                            .update({'stopOrdering': value});
                      },
                    ),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.vertical_align_top,
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(AppLocalizations.of(context)
                            .translate('Maximum order price'))
                      ],
                    ),
                    Container(
                        width: 50,
                        child: TextField(
                          controller: maximumOrderPriceController,
                          cursorColor: kPrimary,
                          decoration: kinputFiledDecoration,
                        )),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.vertical_align_bottom,
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(AppLocalizations.of(context)
                            .translate('Minimum order price')),
                      ],
                    ),
                    Container(
                        width: 50,
                        child: TextField(
                          controller: minimumOrderPriceController,
                          cursorColor: kPrimary,
                          decoration: kinputFiledDecoration,
                        )),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            FontAwesome.truck,
                            color: Colors.grey.shade700,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).translate(
                                  'Delivery fee under maximum order price'),
                              maxLines: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: 50,
                        child: TextField(
                          controller:
                              deliveryFeeUnderMaximumOrderPriceController,
                          cursorColor: kPrimary,
                          decoration: kinputFiledDecoration,
                        )),
                  ],
                ),
                FlatButton(
                  child: Text(
                    AppLocalizations.of(context).translate('Apply changes'),
                    style: TextStyle(color: kPrimary),
                  ),
                  onPressed: () {
                    settings.minimumOrderPrice =
                        double.tryParse(minimumOrderPriceController.text);
                    settings.maximumOrderPrice =
                        double.tryParse(maximumOrderPriceController.text);
                    settings.deliveryFeeUnderMaximumOrderPrice =
                        double.tryParse(
                            deliveryFeeUnderMaximumOrderPriceController.text);
                    FirebaseFirestore.instance
                        .collection('/settings')
                        .doc('settings')
                        .set(settings.toJson())
                        .then((value) =>
                            Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .translate('Data saved')),
                              backgroundColor: kPrimary,
                            )))
                          ..catchError((arg) =>
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)
                                    .translate('Error')),
                                backgroundColor: kPrimary,
                              )));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
