import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stack_trace/stack_trace.dart';

class FlutterRaygun {
  static const MethodChannel _channel = const MethodChannel('flutter_raygun');
  static final FlutterRaygun _singleton = FlutterRaygun._();

  FlutterRaygun._();

  factory FlutterRaygun() => _singleton;

  /// Initializes the Crashlytics plugin.
  /// If you want to opt in into sending the reports please first call this method.
  Future<void> initialize(
    String apikey, {
    bool pulse = false,
    bool networkLogging = false,
  }) async =>
      await _channel.invokeMethod('initialize', {
        'apikey': apikey,
        'pulse': pulse,
        'networkLogging': networkLogging,
      });

  /// Reports an Error to Craslytics.
  /// A good rule of thumb is not to catch Errors as those are errors that occur
  /// in the development phase.
  ///
  /// This method provides the option In case you want to catch them anyhow.
  /// @deprecated please use reportCrash
  Future<void> onError(FlutterErrorDetails details,
      {bool forceCrash = false}) async {
    final data = {
      'message': details.exception.toString(),
      'cause': details.stack == null ? 'unknown' : _cause(details.stack),
      'trace': details.stack == null ? [] : _traces(details.stack),
      'forceCrash': forceCrash
    };

    return await _channel.invokeMethod('reportCrash', data);
  }

  Future<void> reportCrash(dynamic error, StackTrace stackTrace,
      {bool forceCrash = false}) async {
    final data = {
      'message': error.toString(),
      'cause': stackTrace == null ? 'unknown' : _cause(stackTrace),
      'trace': stackTrace == null ? [] : _traces(stackTrace),
      'forceCrash': forceCrash
    };

    return await _channel.invokeMethod('reportCrash', data);
  }

  Future<void> logException(dynamic exception, StackTrace stackTrace) {
    return reportCrash(exception, stackTrace);
  }

  Future<void> log(
    String msg, {
    bool send = false,
    Iterable<String> tags = const [],
  }) async {
    await _channel.invokeMethod('log', {
      'message': msg,
      'send': send,
      'tags': tags,
    });
  }

  Future<void> setTags(List<String> tags) async {
    return await _channel.invokeMethod('setTags', tags);
  }

  Future<void> setInfo(String key, dynamic info) async {
    return await _channel.invokeMethod('setInfo', {"key": key, "value": info});
  }

  Future<void> setUserInfo(
    String identifier,
    String email,
    String name,
    String firstname,
  ) async {
    return await _channel.invokeMethod('setUserInfo', {
      "id": identifier,
      "email": email,
      "name": name,
      'firstname': firstname
    });
  }

  List<Map<String, dynamic>> _traces(StackTrace stack) =>
      Trace.from(stack).frames.map(_toTrace).toList(growable: false);

  String _cause(StackTrace stack) => Trace.from(stack).frames.first.toString();

  Map<String, dynamic> _toTrace(Frame frame) {
    final List<String> tokens = frame.member.split('.');

    return {
      'library': frame.library ?? 'unknown',
      'line': frame.line ?? 0,
      // Global function might have thrown the exception.
      // So in some cases the method is the first token
      'method': tokens.length == 1 ? tokens[0] : tokens.sublist(1).join('.'),
      // Global function might have thrown the exception.
      // So in some cases class does not exist
      'class': tokens.length == 1 ? null : tokens[0],
    };
  }
}
