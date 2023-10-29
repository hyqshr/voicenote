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
    print(audioToTextMap.length.toString() + " audio files found");
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
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
  );
  // Define the text color based on the theme's brightness
  Color textColor = isDarkMode ? Colors.white : Colors.black;

  return MaterialApp(
    theme: themeData,
    home: Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
           SliverAppBar(
            pinned: true, // This ensures the app bar remains visible as you scroll.
            expandedHeight: 100.0, // This is the height when the app bar is fully expanded.
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Voice Notes", style: TextStyle(color: textColor),),
              // background: FlutterLogo(), // You can change this to any other widget or image.
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                SearchBarApp(
                  toggleDarkMode: _toggleDarkMode,
                  setPrompt: _setPrompt,
                ),
                
                AudioList(audioToTextMap: audioToTextMap), 
                
              ]
            ),
          ),
        ],
        
      ),
          bottomNavigationBar: BottomAppBar(
            child: AudioRecorder(onUpdate: (){
              setState(() {});
              _fetchAudios();
            },
                ),
          )
    ),
  );
}

}
