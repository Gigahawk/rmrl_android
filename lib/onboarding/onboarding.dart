import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:rmrl_android/onboarding/onboarding_intro.dart';
import 'package:rmrl_android/onboarding/onboarding_select.dart';
import 'package:rmrl_android/shared_prefs/shared_prefs.dart';
import 'package:rmrl_android/navigation/navigation.dart';
import 'package:rmrl_android/doc_view/doc_view.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


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

  void validateSrc() {
    validateUri(true);
  }

  void validateDst() {
    validateUri(false);
  }

  void validateUri(bool srcSelect) async {
    final result = await checkFolderPath(srcSelect);
    bool validPath = result.item1;
    Uri? uri = result.item2;
    String? path = uri?.toString();

    if (validPath) {
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
      showError();
    }
  }

  Future<void> showError() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Error"),
              content: const Text("Selected folders must be unique"),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    prevPage();
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
            validateSrc();
            break;
          case 2:
            validateDst();
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
