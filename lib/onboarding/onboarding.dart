import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:rmrl_android/onboarding/onboarding_intro.dart';
import 'package:rmrl_android/onboarding/onboarding_select.dart';
import 'package:rmrl_android/shared_prefs/shared_prefs.dart';
import 'package:rmrl_android/navigation/navigation.dart';
import 'package:rmrl_android/doc_view/doc_view.dart';
import 'package:rmrl_android/util/native.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final GlobalKey _globalKey = GlobalKey();
  bool nextEnabled = true;
  String? srcPath;
  String? dstPath;

  @override
  void initState() {
    super.initState();
    checkSkipOnboarding();
  }

  Future<void> checkSkipOnboarding() async {
    bool foldersUnique = await checkFoldersUnique();
    if(foldersUnique) {
      exitOnboarding();
    }

    // Short delay to avoid removing the splash screen mid transition
    // TODO: Option to remove animation from exitOnboarding()
    await Future.delayed(const Duration(milliseconds: 100));
    FlutterNativeSplash.remove();
  }

  void exitOnboarding() {
    navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const DocViewPage()));
  }

  void validateSrc({bool validate = true}) {
    validateUri(true, showErrorPrompt: validate);
  }

  void validateDst({bool validate = true}) {
    validateUri(false, showErrorPrompt: validate);
  }

  void validateUri(bool srcSelect, {bool showErrorPrompt = true}) async {
    final result = await checkFolderPath(srcSelect);
    bool pathExists = result.item1;
    Uri? uri = result.item2;
    String? path;
    bool validPath = await isAcceptableFolderUri(uri!);
    if (!validPath) {
      if (showErrorPrompt) {
        showError("Please pick a different folder");
      }
      return;
    }

    path = await getFolderPathStringFromUri(uri);

    if (pathExists) {
      setState(() {
        if (srcSelect) {
          srcPath = path;
        } else {
          dstPath = path;
        }
      });
      enableNext();
    } else {
      enableNext(enable: false);
    }
  }

  void enableNext({bool enable = true}) {
    setState(() {
      nextEnabled = enable;
    });
  }

  void nextPage() {
    IntroductionScreenState state = _globalKey.currentState as IntroductionScreenState;
    state.next();
  }

  void prevPage() {
    IntroductionScreenState state = _globalKey.currentState as IntroductionScreenState;
    state.previous();
  }

  void finish() async {
    bool foldersUnique = await checkFoldersUnique();
    if (foldersUnique) {
      exitOnboarding();
    } else {
      await showError("Selected folders must be unique");
    }
  }

  Future<void> showError(String msg) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Error"),
              content: Text(msg),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ]
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    ElevatedButton nextButton = ElevatedButton(
        onPressed: nextEnabled ? nextPage : null,
        child: const Text("Next")
    );
    ElevatedButton backButton = ElevatedButton(
        onPressed: prevPage,
        child: const Text("Back")
    );
    ElevatedButton doneButton = ElevatedButton(
        onPressed: nextEnabled ? finish : null,
        child: const Text("Done")
    );
    IntroductionScreen introScreen = IntroductionScreen(
      key: _globalKey,
      pages: [
        OnboardingIntro(),
        OnboardingSelect(
            srcSelect: true,
            onSuccess: validateSrc,
            folderPath: srcPath
        ),
        OnboardingSelect(
            srcSelect: false,
            onSuccess: validateDst,
            folderPath: dstPath
        ),
      ],
      done: const Text("Done"),
      freeze: true,
      onDone: () {},
      onChange: (page) {
        switch(page) {
          case 1:
            validateSrc(validate: false);
            break;
          case 2:
            validateDst(validate: false);
            break;
        }
      },
      showBackButton: true,
      overrideBack: backButton,
      overrideNext: nextButton,
      overrideDone: doneButton,
    );
    return introScreen;
  }
}
