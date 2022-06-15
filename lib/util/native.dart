import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

const platform = MethodChannel('com.gigahawk.rmrl_android');

Future<bool> isAcceptableFolderUri(Uri uri) async {
  try {
    return await platform.invokeMethod(
        'isAcceptableFolderUriString',
        <String, String>{
          'uri': uri.toString()
        });
  } on PlatformException catch (e) {
    print("Error getting path");
    print(e.message);
    return false;
  }
}

Future<Uri?> convertToPdf(String uuid, String docName, Map<String, Uint8List?> fileData) async {
  try {
    String uriString = await platform.invokeMethod(
        'convertToPdf',
        <String, dynamic>{
          'uuid': uuid,
          'docName': docName,
          'fileData': fileData
        });
    Uri uri = Uri.parse(uriString);
    return uri;
  } on PlatformException catch (e) {
    print("Error converting to pdf $uuid");
    print(e.message);
    return null;
  }
}

Future openPdfFromUri(Uri uri) async {
  try {
    return await platform.invokeMethod(
        "openPdfFromUriString",
        <String, String>{
          "uri": uri.toString()
        });
  } on PlatformException catch (e) {
    print("Error opening to pdf $uri");
    print(e.message);
    return;
}
}

Future<String> getFolderPathStringFromUri(Uri uri) async {
  print("Getting path string");
  try {
    return await platform.invokeMethod(
        'getFolderPathStringFromUriString',
        <String, String>{
          'uri': uri.toString()
        });
  } on PlatformException catch (e) {
    print("Error getting path");
    print(e.message);
    return "error";
  }
}
