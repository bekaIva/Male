import 'dart:typed_data';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:male/Constants/Constants.dart';
import 'package:male/Localizations/app_localizations.dart';
import 'package:male/Models/Order.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Uitls/Utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> exportInvoice(
    {PdfPageFormat pageFormat, Order order, BuildContext bContext}) async {
  final lorem = pw.LoremText();

  final invoice = Invoice(
    invoiceNumber: order.orderId.toString(),
    products: order.products,
    customerName: order.deliveryAddress.name,
    customerAddress: order.deliveryAddress.address,
    paymentInfo: EnumToString.parse(order.paymentStatus),
    deliveryFee: order.deliveryFee,
    baseColor: PdfColor(kPrimary.red.toDouble() / 255,
        kPrimary.green.toDouble() / 255, kPrimary.blue.toDouble() / 255),
    accentColor: PdfColors.blueGrey900,
  );

  return await invoice.buildPdf(pageFormat, bContext);
}

class Invoice {
  Invoice({
    this.products,
    this.customerName,
    this.customerAddress,
    this.invoiceNumber,
    this.deliveryFee,
    this.paymentInfo,
    this.baseColor,
    this.accentColor,
  });

  final List<Product> products;
  final String customerName;
  final String customerAddress;
  final String invoiceNumber;
  final double deliveryFee;
  final String paymentInfo;
  final PdfColor baseColor;
  final PdfColor accentColor;

  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;

  PdfColor get _baseTextColor =>
      baseColor.luminance < 0.5 ? _lightColor : _darkColor;

  PdfColor get _accentTextColor =>
      baseColor.luminance < 0.5 ? _lightColor : _darkColor;

  double get _total => products.fold(
      0,
      (previousValue, element) =>
          previousValue +
          (element.totalProductPrice * (element.quantity ?? 1)));

  double get _grandTotal => _total + deliveryFee;

  PdfImage _logo;

  Future<Uint8List> buildPdf(
      PdfPageFormat pageFormat, BuildContext bContext) async {
    // Create a PDF document.
    final doc = pw.Document();

    final font1 = await rootBundle.load('assets/sylfaen.ttf');
    final font2 = await rootBundle.load('assets/sylfaen.ttf');
    final font3 = await rootBundle.load('assets/sylfaen.ttf');

    _logo = PdfImage.file(
      doc.document,
      bytes: (await rootBundle.load('assets/appLogo.png')).buffer.asUint8List(),
    );

    // Add page to the PDF
    doc.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(
          pageFormat,
          font1 != null ? pw.Font.ttf(font1) : null,
          font2 != null ? pw.Font.ttf(font2) : null,
          font3 != null ? pw.Font.ttf(font3) : null,
        ),
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          height: 50,
                          padding: const pw.EdgeInsets.only(left: 20),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            AppLocalizations.of(bContext).translate('INVOICE'),
                            style: pw.TextStyle(
                              color: baseColor,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                        ),
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            borderRadius: 2,
                            color: accentColor,
                          ),
                          padding: const pw.EdgeInsets.only(
                              left: 40, top: 10, bottom: 10, right: 20),
                          alignment: pw.Alignment.centerLeft,
                          height: 50,
                          child: pw.DefaultTextStyle(
                            style: pw.TextStyle(
                              color: _accentTextColor,
                              fontSize: 12,
                            ),
                            child: pw.GridView(
                              crossAxisCount: 2,
                              children: [
                                pw.Text(
                                    '${AppLocalizations.of(bContext).translate('Invoice')} #: '),
                                pw.Text(invoiceNumber),
                                pw.Text(
                                    '${AppLocalizations.of(bContext).translate('Date')}: '),
                                pw.Text(DateFormat.yMMMMd(
                                        AppLocalizations.of(bContext)
                                            .locale
                                            .languageCode)
                                    .format(DateTime.now())),
                                //final format = DateFormat.yMMMMd('en_US');
                                //   return format.format(date);
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.topRight,
                          padding:
                              const pw.EdgeInsets.only(bottom: 8, left: 30),
                          height: 72,
                          child: _logo != null ? pw.Image(_logo) : pw.PdfLogo(),
                        ),
                        // pw.Container(
                        //   color: baseColor,
                        //   padding: pw.EdgeInsets.only(top: 3),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              if (context.pageNumber > 1) pw.SizedBox(height: 20)
            ],
          );
        },
        footer: _buildFooter,
        build: (context) => [
          _contentHeader(context, bContext),
          _contentTable(context, bContext),
          pw.SizedBox(height: 20),
          _contentFooter(context, bContext),
          pw.SizedBox(height: 20),
          //_termsAndConditions(context),
        ],
      ),
    );

    // Return the PDF file content
    return doc.save();
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          height: 20,
          width: 100,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.pdf417(),
            data: 'Invoice# $invoiceNumber',
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey,
          ),
        ),
      ],
    );
  }

  pw.PageTheme _buildTheme(
      PdfPageFormat pageFormat, pw.Font base, pw.Font bold, pw.Font italic) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: italic,
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            pw.Positioned(
              bottom: 0,
              left: 0,
              child: pw.Container(
                height: 20,
                width: pageFormat.width / 2,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [baseColor, PdfColors.white],
                  ),
                ),
              ),
            ),
            pw.Positioned(
              bottom: 20,
              left: 0,
              child: pw.Container(
                height: 20,
                width: pageFormat.width / 4,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [accentColor, PdfColors.white],
                  ),
                ),
              ),
            ),
            pw.Positioned(
              top: pageFormat.marginTop + 72,
              left: 0,
              right: 0,
              child: pw.Container(
                height: 3,
                color: baseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _contentHeader(pw.Context context, BuildContext bContext) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
            height: 70,
            child: pw.FittedBox(
              child: pw.Text(
                '${AppLocalizations.of(bContext).translate('Total')}: ${_formatCurrency(_grandTotal)}',
                style: pw.TextStyle(
                  color: baseColor,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(left: 10, right: 10),
                height: 70,
                child: pw.Text(
                  '${AppLocalizations.of(bContext).translate('Invoice to')}: ',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 70,
                  child: pw.RichText(
                      text: pw.TextSpan(
                          text: '$customerName\n',
                          style: pw.TextStyle(
                            color: _darkColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                        const pw.TextSpan(
                          text: '\n',
                          style: pw.TextStyle(
                            fontSize: 5,
                          ),
                        ),
                        pw.TextSpan(
                          text: customerAddress,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.normal,
                            fontSize: 10,
                          ),
                        ),
                      ])),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _contentFooter(pw.Context context, BuildContext bContext) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                AppLocalizations.of(bContext)
                    .translate('Thank you for your business'),
                style: pw.TextStyle(
                  color: _darkColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
                child: pw.Text(
                  '${AppLocalizations.of(bContext).translate('Payment Info')}: ',
                  style: pw.TextStyle(
                    color: baseColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                AppLocalizations.of(bContext).translate(paymentInfo),
                style: const pw.TextStyle(
                  fontSize: 8,
                  lineSpacing: 5,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.DefaultTextStyle(
            style: const pw.TextStyle(
              fontSize: 10,
              color: _darkColor,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        AppLocalizations.of(bContext).translate('Sub Total')),
                    pw.Text(_formatCurrency(_total)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(AppLocalizations.of(bContext)
                        .translate('Delivery fee')),
                    pw.Text('₾${deliveryFee.toStringAsFixed(1)}'),
                  ],
                ),
                pw.Divider(color: accentColor),
                pw.DefaultTextStyle(
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          '${AppLocalizations.of(bContext).translate('Total')}:'),
                      pw.Text(_formatCurrency(_grandTotal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _termsAndConditions(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.BoxBorder(
                    top: true,
                    color: accentColor,
                  ),
                ),
                padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                child: pw.Text(
                  'Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: baseColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                pw.LoremText().paragraph(40),
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(
                  fontSize: 6,
                  lineSpacing: 2,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.SizedBox(),
        ),
      ],
    );
  }

  pw.Widget _contentTable(pw.Context context, BuildContext bContext) {
    var tableHeaders = [
      AppLocalizations.of(bContext).translate('Name'),
      AppLocalizations.of(bContext).translate('Description'),
      AppLocalizations.of(bContext).translate('Quantity'),
      AppLocalizations.of(bContext).translate('Price'),
      AppLocalizations.of(bContext).translate('Total'),
    ];

    return pw.Table.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(
        borderRadius: 2,
        color: baseColor,
      ),
      headerHeight: 25,
      cellHeight: 20,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(
        color: _baseTextColor,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: _darkColor,
        fontSize: 10,
      ),
      rowDecoration: pw.BoxDecoration(
        border: pw.BoxBorder(
          top: true,
          color: PdfColor.fromRYB(
              kPrimary.red / 255, kPrimary.green / 255, kPrimary.blue / 255),
          width: .5,
        ),
      ),
      headers: List<String>.generate(
        tableHeaders.length,
        (col) => tableHeaders[col],
      ),
      data: List<List<String>>.generate(
        products.length + 1,
        (row) {
          if (row == products.length)
            return List<String>.generate(tableHeaders.length, (c) => '');
          return List<String>.generate(
            tableHeaders.length,
            (col) => () {
              switch (col) {
                case 0:
                  return getLocalizedName(
                      products[row].localizedName, bContext);
                case 1:
                  // '${getLocalizedName(products[row].localizedDescription, bContext)}'
                  //     ' ${products[row].addonDescriptions?.fold('', (previousValue, element) => previousValue + '${getLocalizedName(element.localizedAddonDescriptionName, bContext)}: '
                  //     '${getLocalizedName(element.localizedAddonDescription, bContext)}')}'
                  return '${products[row].checkedAddon?.localizedName != null ? '\n' + getLocalizedName(products[row].checkedAddon?.localizedName, bContext) : ''} ${products[row].checkedAddon?.price != null ? ' +${products[row].checkedAddon?.price}₾' : ''} \n${products[row].selectedSelectableAddons?.fold('', (previousValue, element) => previousValue + getLocalizedName(element.localizedName, bContext) + '${element?.price != null ? ' +${element.price}₾' : ''}\n') ?? ''}';
                case 2:
                  return (products[row].quantity ?? 1).toString();
                case 3:
                  return products[row].totalProductPrice.toStringAsFixed(2);

                case 4:
                  return ((products[row].totalProductPrice) *
                          (products[row].quantity ?? 1))
                      .toStringAsFixed(2);
              }
            }(),
          );
        },
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return '\₾${amount.toStringAsFixed(2)}';
}
