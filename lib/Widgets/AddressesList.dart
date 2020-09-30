import 'package:flutter/material.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Address.dart';

class AddressesList extends StatefulWidget {
  final bool isReadOnly;
  final Function(UserAddress) addressSelected;
  final List<UserAddress> userAddresses;
  AddressesList(
      {this.userAddresses, this.addressSelected, this.isReadOnly = false});
  @override
  _AddressesListState createState() => _AddressesListState();
}

class _AddressesListState extends State<AddressesList> {
  int selectedValue = -1;
  @override
  Widget build(BuildContext context) {
    selectedValue = -1;
    if ((widget.userAddresses?.length ?? 0) > 0) {
      for (int i = 0; i < widget.userAddresses.length; i++) {
        if (widget.userAddresses[i].isPrimary ?? false) {
          selectedValue = i;
          widget.addressSelected?.call(widget.userAddresses[i]);
          break;
        }
      }
    }
    return Column(
        children: widget.userAddresses.map((e) {
      return RadioListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: Text(e.name)),
            SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                e.addressName ?? '',
                style: TextStyle(color: Colors.black54),
              ),
            )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.address),
            Text(
                '${AppLocalizations.of(context).translate('Phone')} ${e.mobileNumber}')
          ],
        ),
        secondary: FlatButton(
          splashColor: kPrimary.withOpacity(0.2),
          highlightColor: kPrimary.withOpacity(.2),
          child: Text(
            AppLocalizations.of(context).translate('Delete'),
            style: TextStyle(color: kPrimary),
          ),
          onPressed: () {
            e.referance.delete();
          },
        ),
        activeColor: kPrimary,
        value: selectedValue,
        groupValue: widget.userAddresses.indexOf(e),
        onChanged: !widget.isReadOnly
            ? (val) {
                try {
                  widget.userAddresses[val].referance
                      .update({'isPrimary': false});
                } catch (e) {}

                e.referance.update({'isPrimary': true});
                widget.addressSelected?.call(e);
                setState(() {
                  selectedValue = widget.userAddresses.indexOf(e);
                });
              }
            : null,
      );
    }).toList());
  }
}
