import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class AudioRecorder extends StatefulWidget {
  final VoidCallback onUpdate;

  const AudioRecorder({
    Key? key,
    required this.onUpdate,
    }) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;
  final FFmpegKit _flutterFFmpeg = FFmpegKit();

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => setState(() => _amplitude = amp));

    super.initState();
  }

  Future<void> convertMp4ToWav(String inputPath, String outputPath) async {
    final arguments = [
      '-i',
      inputPath,
      '-ac',
      '1',
      '-ar',
      '16000',
      '-acodec',
      'pcm_s16le',
      outputPath,
    ];
    await FFmpegKit.execute(arguments.join(' '));
  }

Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        
        // Get the app's directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String recordingsDirPath = '${appDir.path}';
        
        // Create a folder named 'Recordings' if it doesn't exist
        final Directory recordingsDir = Directory(recordingsDirPath);
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        
        // Get the next available file name
        final String newRecordingName = await _getNextAvailableFileName(recordingsDirPath);
        
        await _audioRecorder.start(path: '$recordingsDirPath/$newRecordingName.m4a'); // Specify the path to save the recording
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<String> _getNextAvailableFileName(String recordingsDirPath) async {
    int i = 1;
    while (await File('$recordingsDirPath/New_Recording_$i.wav').exists()) {
      i++;
    }
    return 'New_Recording_$i';
  }

  void deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print('File deleted successfully');
    } else {
      print('File does not exist');
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    String? path = await _audioRecorder.stop();
    debugPrint("path!: $path");
    String wavPath = path!.replaceAll(".m4a", ".wav");
    await convertMp4ToWav(path, wavPath);
    deleteFile(path);

    wavPath = wavPath.replaceAll("file://", "");
    //override path
    path = wavPath;
    widget.onUpdate();
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: _recordState != RecordState.stop ?MainAxisAlignment.spaceAround : MainAxisAlignment.center,
      children: [
        _buildText(),
        _buildRecordStopControl(),
        if (_recordState != RecordState.stop) ...[
          _buildPauseResumeControl(),
        ]
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop_circle_outlined, color: Colors.lightBlue, size: 65);
    } else {
      icon = const Icon(Icons.brightness_1_outlined, color: Color.fromARGB(255, 147, 195, 234), size: 65);
    }

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            child: icon,
            onTap: () {
              (_recordState != RecordState.stop) ? _stop() : _start();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPauseResumeControl() {

    late Icon icon;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 65);
    } else {
      icon = const Icon(Icons.play_arrow_rounded, color: Colors.red, size: 65);
    }
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            child: icon,
            onTap: () {
              (_recordState == RecordState.pause) ? _resume() : _pause();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return Container();
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w300,
        ),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}