import 'dart:async';
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_gpt/bridge_generated.dart';

class AudioWidget extends StatefulWidget {
  final String source;
  final RsWhisperGptImpl api;
  /// Callback when audio file should be removed
  /// Setting this to null hides the delete button
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
      icon = Icon(Icons.play_arrow, color: theme.primaryColor, size: 30);
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
        activeColor: Theme.of(context).primaryColor,
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
    final baseFilePath = widget.source.replaceAll('.wav', '');
    final filePath = '$baseFilePath.txt';
    final file = File(filePath);
    await file.writeAsString(transcribedText!);
  }

  Widget _buildTranscribeButton() {
    if (transcribedText == null) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton(
          child: const Text("Transcribe text"),
          onPressed: () async {
            final value = await widget.api.runWhisperModel(path: widget.source, lang: 'en');
            setState(() {
              transcribedText = value.join(" ");
            });
            await _saveTranscribedTextToFile();
          }
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
              child: Text(
                transcribedText!,
              )));
    }
    return Container();
  }

  Future<void> pause() => _audioPlayer.pause();

  Future<void> stop() => _audioPlayer.stop();
}
