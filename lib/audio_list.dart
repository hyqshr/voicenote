import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'dart:ffi';
import 'dart:io';
import "audio_record.dart";
import 'package:whisper_gpt/bridge_generated.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'audio_widget.dart';

const base = 'rs_whisper_gpt';
final lib_path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = Platform.isIOS
    ? DynamicLibrary.process()
    : Platform.isMacOS
        ? DynamicLibrary.executable()
        : DynamicLibrary.open(lib_path);

final api = RsWhisperGptImpl(dylib);


class AudioList extends StatefulWidget {
  @override
  _AudioListState createState() => _AudioListState();
}

class _AudioListState extends State<AudioList> {
  List<File> audioFiles = [];
  final player = ap.AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  _fetchAudios() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingDir = Directory(path.join(appDir.path));
    if (await recordingDir.exists()) {
      final entities = recordingDir.listSync();
      for (var entity in entities) {
        if (entity is File && path.extension(entity.path) == '.wav') {
          setState(() {
            audioFiles.add(entity);
          });
        }
      }
    }
  }

  void _deleteAudio(File file) async {
    try {
      await file.delete();
      setState(() {
        audioFiles.remove(file);
      });
    } catch (e) {
      print("Error deleting file: $e");
      // You can also show a dialog or a snackbar to notify the user about the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: audioFiles.length,
      itemBuilder: (context, index) {
        return ExpansionTileCard(
          title: Text(path.basenameWithoutExtension(audioFiles[index].path)),
          children: <Widget>[
            AudioWidget(
              source: audioFiles[index].path, 
              api: api,
              onDelete: () {
                  _deleteAudio(audioFiles[index]);
                  setState(() => ());
                },
              )
          ],
        );
      },
    );
  }

}
