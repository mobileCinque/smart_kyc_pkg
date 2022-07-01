library smart_kyc_pkg;

import 'dart:io';

import 'dart:async';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

class MLVision extends StatelessWidget {
  String? _imagePath;
  String? _eidText;
  String? _name;
  String? _idNo;
  String? _national;

  TextRecognizer detector = GoogleVision.instance.textRecognizer();
  final eidNumber = RegExp('^(784-[0-9]{4}-[0-9]{7}-[0-9]{1})');

  bool getCardIssuer(String idNumber) {
    return eidNumber.hasMatch(idNumber);
  }

  Future<void> getImage() async {
    String? imagePath;
    String? text;

    var idInfo = EmiratesIDFrontInfo();
    var str = "";

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      imagePath = (await EdgeDetection.detectEdge);
      print("$imagePath");
      final File imageFile = File(imagePath ?? '');
      final GoogleVisionImage visionImage =
          GoogleVisionImage.fromFile(imageFile);
      final VisionText visionText = await detector.processImage(visionImage);
      text = visionText.text;
      text!.split("\n").forEach((str) async {
        // print("str: " + str);
        if (str.replaceAll("\n", " ").toLowerCase().contains("name")) {
          final nameAtt = str.toLowerCase().split(":");
          idInfo.holderName = nameAtt[1];
        }

        if (str.toLowerCase().contains("nationality".trim())) {
          final national = str.toLowerCase().split(":");

          idInfo.nationality = national[1];
        }

        idInfo.isValidID = getCardIssuer(str);
        if (idInfo.isValidID) {
          idInfo.idNumber = str;
        }
      });
      print("holder name is : " + idInfo.holderName);
      print("nationality is : " + idInfo.nationality);
      print("idNumber is : " + idInfo.idNumber);

      print(text);
    } on PlatformException catch (e) {
      imagePath = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _imagePath = imagePath;
      _eidText = text;

      _name = idInfo.holderName;
      _idNo = idInfo.idNumber;
      _national = idInfo.nationality;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: getImage,
              child: Text('Scan'),
            ),
          ),
          SizedBox(height: 20),
          Text('Scanned info:'),
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
            child: Text(
              _eidText.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Visibility(
            visible: _imagePath != null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(
                File(_imagePath ?? ''),
              ),
            ),
          ),
          Visibility(
            visible: _name != null,
            child: Container(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Name is : " + _name.toString(),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ))),
          ),
          Visibility(
            visible: _idNo != null,
            child: Container(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "EID number is : " + _idNo.toString(),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ))),
          ),
        ],
      ),
    );
  }
}

class EmiratesIDFrontInfo {
  String idNumber = "";
  String holderName = "";
  String nationality = "";
  bool isValidID = false;

  // bool get isValidID {
  //   return _isValidID;
  // }

  // set isValidID(bool isValidID) {
  //   this._isValidID = isValidID;
  // }

  bool isFrontDataCaptured() {
    if (idNumber.isNotEmpty &&
        holderName.isNotEmpty &&
        nationality.isNotEmpty &&
        isValidID) {
      return true;
    }
    return false;
  }
}
