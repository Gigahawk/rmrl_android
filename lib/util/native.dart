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

Future<bool> convertToPdf(String uuid, String docName, Map<String, Uint8List?> fileData) async {
  try {
    await platform.invokeMethod(
        'convertToPdf',
        <String, dynamic>{
          'uuid': uuid,
          'docName': docName,
          'fileData': fileData
        });
    return true;
  } on PlatformException catch (e) {
    print("Error converting to pdf $uuid");
    print(e.message);
    return false;
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
