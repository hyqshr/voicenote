import 'package:flutter/material.dart';
import 'audio_record.dart';
import 'audio_list.dart';
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'dart:io';
import 'package:path/path.dart' as path;

import 'searchbar.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isDarkMode = false;
  String prompt = "";

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }
  Map<File, String?> audioToTextMap = {};

  _fetchAudios() async {
    audioToTextMap.clear(); // Clear the map first
    final appDir = await getApplicationDocumentsDirectory();
    final recordingDir = Directory(path.join(appDir.path));
    if (await recordingDir.exists()) {
      final entities = recordingDir.listSync();
      for (var entity in entities) {
        if (entity is File && path.extension(entity.path) == '.wav') {
          final txtFile = File(entity.path.replaceFirst('.wav', '.txt'));
          String? txtContent;
          if (await txtFile.exists()) {
            txtContent = await txtFile.readAsString();
          } else {
            txtContent = null;
          }
          setState(() {
            audioToTextMap[entity] = txtContent;
          });
        }
      }
    }
  }

  _toggleDarkMode(){
    debugPrint("Toggle dark mode");
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  _setPrompt(String prompt){
    setState(() {
      this.prompt = prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = ThemeData(
    useMaterial3: true,
    brightness: isDarkMode ? Brightness.dark : Brightness.light);

    return MaterialApp(
      theme: themeData,
      home: Scaffold(
      appBar: AppBar(title: Text("Voice Notes"),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, 
        children: [
          SearchBarApp(
            toggleDarkMode: _toggleDarkMode,
            setPrompt: _setPrompt,
          ),
          Expanded(child: AudioList(audioToTextMap: audioToTextMap)), 
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              top: 12.0,
              right: 12.0,
              bottom: 24.0,  // Increased padding at the bottom
            ),
            child: AudioRecorder(onUpdate: (){
              setState(() {});
              _fetchAudios();
            },),
          ),
        ],
      ),
    ),
    );
  }
}
