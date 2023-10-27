import 'package:flutter/material.dart';
import 'audio_record.dart';
import 'audio_list.dart';
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'dart:io';
import 'package:path/path.dart' as path;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, 
          children: [
            Expanded(child: AudioList(audioToTextMap: audioToTextMap)), 
            AudioRecorder(onUpdate: (){
              setState(() {});
              _fetchAudios();
            },),
          ],
        ),
      ),
    );
  }
}