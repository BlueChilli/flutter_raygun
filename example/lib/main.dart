import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:raygun/raygun.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (!kReleaseMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Raygun.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  bool optIn = true;
  if (optIn) {
    //await FlutterRaygun().initialize('LdG17EB/6i21JTKqBhD+ww==');
    await FlutterRaygun().initialize('7fIIRatS5AGaIM9+n2hhbQ==');
  } else {
    // In this case Raygun won't send any reports.
    // Usually handling opt in/out is required by the Privacy Regulations
  }

  runZoned<Future<void>>(() async {
    runApp(MyApp());
  }, onError: (error, stackTrace) async {
    // Whenever an error occurs, call the `reportCrash` function. This will send
    // Dart errors to our dev console or Raygun depending on the environment.
    debugPrint(error.toString());
    await FlutterRaygun().reportCrash(error, stackTrace, forceCrash: false);
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: RaisedButton(
                onPressed: () {
                  final crash = List()[222];
                  debugPrint(crash);
                },
                child: Text('Crash'),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: () {
                  try {
                    final crash = List()[555];
                    debugPrint(crash);
                  } catch (error) {
                    debugPrint(error.toString());
                    FlutterRaygun().logException(error, error.stackTrace);
                  }
                },
                child: Text('Manual error log'),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: () {
                  try {
                    throw new FormatException();
                  } catch (exception, stack) {
                    debugPrint(exception.toString());
                    FlutterRaygun().logException(exception, stack);
                  }
                },
                child: Text('Manual exception log'),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: () {
                  FlutterRaygun().setUserInfo(
                      "SomeUser", "user@bluechilli.com", "Some User", "User");
                  FlutterRaygun().log(
                    "Manual logging",
                    send: true,
                    tags: ["tag1", "tag2"],
                  );
                },
                child: Text('Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
