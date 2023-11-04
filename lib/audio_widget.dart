import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_gpt/bridge_generated.dart';
import 'text_editor.dart';
import 'util.dart';
import 'package:share_plus/share_plus.dart';

class AudioWidget extends StatefulWidget {
  final String source;
  final RsWhisperGptImpl api;
  final VoidCallback onDelete;
  final String? text;

  const AudioWidget({
    Key? key,
    required this.source,
    required this.onDelete,
    required this.api, 
    required this.text,
  }) : super(key: key);

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

class AudioPlayerState extends State<AudioWidget> {
  static const double _controlSize = 40;
  static const double _deleteBtnSize = 20;
  bool _isLoading = false; 
  final _audioPlayer = ap.AudioPlayer();
  String? transcribedText;

  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  Duration? _position;
  Duration? _duration;

  @override
  void initState() {
    if (widget.text != null) {
      debugPrint("Find existing text!!!: ${widget.text}");
      debugPrint("source!!!: ${widget.source}");
      transcribedText = widget.text;
    }
    _playerStateChangedSubscription =
        _audioPlayer.onPlayerComplete.listen((state) async {
      await stop();
      setState(() {});
    });
    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(
      (position) => setState(() {
        _position = position;
      }),
    );
    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) => setState(() {
        _duration = duration;
      }),
    );
    // debugPrint(await _audioPlayer.getDuration().toString());
    super.initState();
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildControl(),
                _buildSlider(constraints.maxWidth * 0.7),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Color(0xFF73748D), size: _deleteBtnSize),
                  onPressed: () {
                    stop().then((value) => widget.onDelete());
                  },
                ),
              ],
            ),
            _buildTranscribeButton(),
            _buildTranscribedText(),
            IconButton(
                icon: const Icon(Icons.share, color: Colors.lightBlue, size: _deleteBtnSize),
                onPressed: () async {
                    try {
                    await Share.shareFiles([widget.source], mimeTypes: ["audio/wav"]);
                  } catch (e) {
                    print('Error while sharing audio: $e');
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildControl() {
    Icon icon;
    Color color;

    if (_audioPlayer.state == ap.PlayerState.playing) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.play_arrow, color: theme.brightness== Brightness.light? theme.primaryColor: Colors.grey, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child:
              SizedBox(width: _controlSize, height: _controlSize, child: icon),
          onTap: () {
            if (_audioPlayer.state == ap.PlayerState.playing) {
              pause();
            } else {
              play();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSlider(double widgetWidth) {
    bool canSetValue = false;
    final duration = _duration;
    final position = _position;

    if (duration != null && position != null) {
      canSetValue = position.inMilliseconds > 0;
      canSetValue &= position.inMilliseconds < duration.inMilliseconds;
    }

    double width = widgetWidth - _controlSize - _deleteBtnSize;
    width -= _deleteBtnSize;

    return SizedBox(
      width: width,
      child: Slider(
        activeColor: Theme.of(context).brightness== Brightness.light? Theme.of(context).primaryColor: Colors.grey,
        inactiveColor: Theme.of(context).colorScheme.secondary,
        onChanged: (v) {
          if (duration != null) {
            final position = v * duration.inMilliseconds;
            _audioPlayer.seek(Duration(milliseconds: position.round()));
          }
        },
        value: canSetValue && duration != null && position != null
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0,
      ),
    );
  }

  Future<void> play() {
    return _audioPlayer.play(
      ap.DeviceFileSource(widget.source),
    );
  }

  Future<void> _saveTranscribedTextToFile() async {
    final baseFilePath = widget.source.replaceAll('.wav', '.json');
    final file = File(baseFilePath);
    String jsonTring = '[{"insert":"${transcribedText!.trim()}\\n"}]';
    debugPrint("saving to $jsonTring -- $baseFilePath");
    await file.writeAsString(jsonTring);
  }
  void _onButtonPressed() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    
    try {
      final value = await widget.api.runWhisperModel(path: widget.source);
      setState(() {
        transcribedText = value.join(" ");
      });
      await _saveTranscribedTextToFile();
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false once the operation is complete
      });
    }
  }


  Widget _buildTranscribeButton() {
    if (transcribedText == null) {
      return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        child: _isLoading
            ?  const SizedBox(
                height: 20.0, // Smaller height
                width: 20.0, // Smaller width
                child: CircularProgressIndicator(
                  strokeWidth: 2.0, // Thinner stroke
                ),
              ) // Show loading indicator when the API is running
            : const Text("Speech to Text"),
        onPressed: _isLoading ? null : _onButtonPressed, // Disable the button when loading
      ),
    );
    };
    return Container();
  }

  Widget _buildTranscribedText() {
    if (transcribedText != null) {
      return FractionallySizedBox(
        widthFactor: 2 / 3,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuillEditorWidget(
                    source: fileWithDiffExtension(widget.source, '.json'),
                  ),
                ),
              );
            },
            child: Text(
              transcribedText!,
            ),
          ),
        ),
      );
    }
    return Container();
  }


  Future<void> pause() => _audioPlayer.pause();

  Future<void> stop() => _audioPlayer.stop();
}
