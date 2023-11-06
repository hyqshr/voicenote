import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'dart:ffi';
import 'package:whisper_gpt/bridge_generated.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'audio_widget.dart';
import 'util.dart';
import 'package:lottie/lottie.dart';

const base = 'rs_whisper_gpt';
final lib_path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = DynamicLibrary.process();
final api = RsWhisperGptImpl(dylib);


class AudioList extends StatefulWidget {
  final Map<File, String?> audioToTextMap;
  final Function onRefresh;

  const AudioList({
    Key? key, 
    required this.audioToTextMap,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _AudioListState createState() => _AudioListState();
}

class _AudioListState extends State<AudioList> {
  final player = ap.AudioPlayer();
  final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  _deleteAudio(File file) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this file?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                Navigator.of(context).pop(); 
                try {
                  print(widget.audioToTextMap);

                  widget.audioToTextMap.remove(file);

                  // setState(() {
                  //   print(widget.audioToTextMap);
                  //   widget.audioToTextMap.remove(file);
                  // });
                  print("after");
                    print(widget.audioToTextMap);

                  await file.delete();
                  File quillJsonFile = File(fileWithDiffExtension(file.path, '.json'));
                  if (await quillJsonFile.exists()) {
                    await quillJsonFile.delete();
                  }
                  await widget.onRefresh();
                } catch (e) {
                  print("Error deleting file: $e");
                  // You can also show a dialog or a snackbar to notify the user about the error
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ignore: non_constant_identifier_names
  Widget PlaceHolder(){
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "🎤 Silence is golden, but voice notes are platinum! Tap to record and make your thoughts heard. ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w200,
              ),
            ),
            const SizedBox(height: 80,),
            Lottie.asset(
              'assets/waveform_light.json',
              width: 70,
              height: 70,
              ),
          ],
        ),
      ),
    );
  }

  void _renamePopupDialog(File file) {
    _renameController.text = path.basenameWithoutExtension(file.path);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename File'),
          content: TextField(
            controller: _renameController,
            decoration: const InputDecoration(hintText: 'Enter new file name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                debugPrint('New file name: ${_renameController.text}');
                await renameFilesWithBaseName(file.path, _renameController.text);
                widget.onRefresh();
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioToTextMap.isEmpty) {
      return Center(child: PlaceHolder());
    } else {
      return SingleChildScrollView(
        child: Column(
          children: widget.audioToTextMap.keys.map((file) {
            return ExpansionTile(
              key: Key(file.path),
              // animateTrailing: false,
              title: GestureDetector(
                onLongPress: () {
                  _renamePopupDialog(file);
                },
                child: Text(path.basenameWithoutExtension(file.path)),
              ),
              trailing: FutureBuilder<String>(
                future: getFileCreationDate(file.path),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Error');
                  } else {
                    return Text(snapshot.data ?? 'Unknown Date');
                  }
                },
              ),
              children: <Widget>[
                AudioWidget(
                  source: file.path,
                  api: api,
                  onDelete: () async {
                    await _deleteAudio(file);
                    await widget.onRefresh();
                  },
                  text: widget.audioToTextMap[file],
                )
              ],
            );
          }).toList(),
        ),
      );
    }
  }
}
