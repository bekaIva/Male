import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF1B6800);
// const Color kPrimary = Color(0xFFFF5722);
const Color kPrimary_dark = Color(0xFF196000);
const Color kPrimary_light = Color(0xFFFFCCBC);
const Color kAccent = Color(0xFFFF5252);
const Color kPrimary_text = Color(0xFF212121);
const Color kIcons = Color(0xFFFFFFFF);
const Color kDivider = Color(0xFFBDBDBD);
const String curencyMark = '₾';
InputDecoration kOutlineInputText = InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 10),
  disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(6)),
  enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(6)),
  errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(6)),
  focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(6)),
  focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
      borderRadius: BorderRadius.circular(6)),
);
const InputDecoration kinputFiledDecoration = InputDecoration(
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: kPrimary),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: kPrimary),
  ),
  border: UnderlineInputBorder(
    borderSide: BorderSide(color: kPrimary),
  ),
  hintStyle: TextStyle(),
);
const TextStyle kSmallHeader = TextStyle(
  fontFamily: 'Sans',
  color: Colors.black54,
  fontWeight: FontWeight.bold,
  fontSize: 12.0,
);
const TextStyle kContentStyle = TextStyle(
  color: Colors.black54,
  fontWeight: FontWeight.w500,
  fontSize: 12.0,
);
const TextStyle kDescriptionTextStyle = TextStyle(
    fontFamily: "Sofia",
    color: Colors.black54,
    fontSize: 16.0,
    fontWeight: FontWeight.w400);
