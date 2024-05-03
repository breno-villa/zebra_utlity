import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:zebrautility/ZebraPrinter.dart';
import 'package:zebrautility/zebrautility.dart';

void main(List<String> args) {
  runApp(
    MaterialApp(
      title: 'Zebra Printer Example',
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late ZebraPrinter _zebraPrinter;
  List<Printer> _discoveredPrinters = [];

  @override
  void initState() {
    super.initState();
    getPrinterInstance();
  }

  getPrinterInstance() async {
    _zebraPrinter = await Zebrautility.getPrinterInstance(
        onPrinterFound: (name, ipAddress, isWifi) {
          _discoveredPrinters.add(Printer(name, ipAddress));
          print(ipAddress);
        },
        onPrinterDiscoveryDone: () {},
        onChangePrinterStatus: (String status, String color) {
          print('status');
        },
        onPermissionDenied: () {
          print('permission denied');
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ElevatedButton(
            onPressed: () async {
              if (await Permission.location.request().isGranted &&
                  // await Permission.bluetooth.request().isGranted &&
                  await Permission.bluetoothScan.request().isGranted &&
                  await Permission.bluetoothConnect.request().isGranted &&
                  await Permission.bluetoothAdvertise.request().isGranted) {
                _discoveredPrinters = [];
                _zebraPrinter.discoveryPrinters();
              }
            },
            child: Text('discoveryPrinters'),
          ),
          ElevatedButton(
            onPressed: () async {
              _zebraPrinter.connectToPrinter(_discoveredPrinters[0].address);
            },
            child: Text('CONNECT'),
          ),
          ElevatedButton(
            onPressed: () async {
              _zebraPrinter.disconnect();
            },
            child: Text('DISCONNECT'),
          ),
          ElevatedButton(
            onPressed: () async {
              final appDocDir = await getTemporaryDirectory();
              var pdf = File('${appDocDir.path}/teste.pdf');
              pdf.writeAsBytes(
                await _generatePdf(
                  const PdfPageFormat(
                    10.4 * PdfPageFormat.cm,
                    2 * PdfPageFormat.cm,
                    marginAll: 20,
                  ),
                ),
              );
              _zebraPrinter.printPdf(pdf.path);
            },
            child: Text('print pdf'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: format,
          // pageFormat: PdfPageFormat(
          //   10.4 * PdfPageFormat.cm,
          //   22 * PdfPageFormat.cm,
          //   marginAll: 20,
          // ),
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.robotoRegular(),
            bold: await PdfGoogleFonts.robotoBold(),
            italic: await PdfGoogleFonts.robotoItalic(),
          ).copyWith(
            defaultTextStyle: const pw.TextStyle(
              fontSize: 7,
            ),
          ),
        ),
        build: (context) => [
          _buildCard(context),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _buildCard(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Nome do Oficial de bloqueio/solicitante: widget.requester ??',
        ),
        pw.Text(
          'Tag do equipamento: widget.equipment.name',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class Printer {
  String name;
  String address;

  Printer(this.name, this.address);
}
