import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:rmrl_android/shared_prefs/shared_prefs.dart';


class OnboardingSelect extends PageViewModel {
  bool srcSelect;
  VoidCallback onSuccess;
  String? folderPath;

  static const String srcTitle = "Select Source Folder";
  static const String dstTitle = "Select Destination Folder";
  static const String srcBody = "This is the folder containing the .metadata files";
  static const String dstBody = "This is the folder to store your output PDFs";


  OnboardingSelect({
    required this.srcSelect,
    required this.onSuccess,
    required this.folderPath,
  }) : super(
    title: srcSelect ? srcTitle : dstTitle,
    body: srcSelect ? srcBody: dstBody,
    footer: Column(
      children: [
        ElevatedButton(
            onPressed: () {
              openDocumentTree().then((Uri? tree) async {
                await storeFolderPath(tree, srcSelect);
                onSuccess();
              });
            },
            child: const Text("Select Folder")
        ),
        Text(folderPath ?? "")
      ],
    )
  );
}