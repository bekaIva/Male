import 'package:flutter/material.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Category.dart';

class itemCard extends StatelessWidget {
  final Function onUpPress;
  final Function onDownPress;
  final Function onCategoryPress;
  final Category category;
  const itemCard(
      {this.category, this.onDownPress, this.onUpPress, this.onCategoryPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 10.0, right: 10.0, top: 8.0, bottom: 5.0),
      child: Container(
        height: 180.0,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        child: Material(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              image: DecorationImage(
                  image: NetworkImage(category.image.downloadUrl),
                  fit: BoxFit.cover),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFABABAB).withOpacity(0.7),
                  blurRadius: 4.0,
                  spreadRadius: 3.0,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
                color: Colors.black12.withOpacity(0.1),
              ),
              child: Stack(
                children: <Widget>[
                  FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0))),
                    onPressed: onCategoryPress,
                    child: Center(
                      child: Text(
                        category.localizedName[AppLocalizations.of(context)
                                .locale
                                .languageCode] ??
                            category.localizedName[
                                AppLocalizations.supportedLocales.first] ??
                            '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          shadows: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 10.0,
                                spreadRadius: 2.0)
                          ],
                          color: Colors.white,
                          fontFamily: "Sofia",
                          fontWeight: FontWeight.w800,
                          fontSize: 39.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (onUpPress != null)
                          Align(
                            alignment: Alignment.topRight,
                            child: RawMaterialButton(
                              onPressed: onUpPress,
                              splashColor: kPrimary.withOpacity(0.3),
                              shape: CircleBorder(),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ),
                        if (onDownPress != null)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: RawMaterialButton(
                              onPressed: onDownPress,
                              splashColor: kPrimary.withOpacity(0.3),
                              shape: CircleBorder(),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
