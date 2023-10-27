import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:whisper_gpt/audio_player.dart';
import 'Home.dart';
import 'dart:ffi';
import 'dart:io';
import "audio_record.dart";
import 'package:whisper_gpt/bridge_generated.dart';

const base = 'rs_whisper_gpt';
final path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = Platform.isIOS
    ? DynamicLibrary.process()
    : Platform.isMacOS
        ? DynamicLibrary.executable()
        : DynamicLibrary.open(path);

final api = RsWhisperGptImpl(dylib);

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? audioPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Home(),
      );
  }
}
