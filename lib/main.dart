import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'Home.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:whisper_gpt/bridge_generated.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


const base = 'rs_whisper_gpt';
final path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = Platform.isIOS
    ? DynamicLibrary.process()
    : Platform.isMacOS
        ? DynamicLibrary.executable()
        : DynamicLibrary.open(path);
final api = RsWhisperGptImpl(dylib);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // init firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

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
    return Home();
  }
}
