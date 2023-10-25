import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:whisper_gpt/audio_player.dart';

import 'package:whisper_gpt/bridge_generated.dart';
import 'dart:ffi';
import 'dart:io';
import "audio_record.dart";

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
  bool showPlayer = false;
  bool showText = false;
  String? audioPath;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Center(
        child: showPlayer
            ? AudioPlayer(
                api: api,
                source: audioPath!,
                onDelete: () {
                  setState(() => showPlayer = false);
                },
              )
            : AudioRecorder(
                onStop: (path) {
                  if (kDebugMode) print('Recorded file path: $path');
                  setState(() {
                    audioPath = path;
                    showPlayer = true;
                  });
                },
              ),
      )),
    );
  }
}
