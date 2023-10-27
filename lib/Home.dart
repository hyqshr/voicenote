import 'package:flutter/material.dart';
import 'audio_record.dart';
import 'audio_list.dart';

class Home extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // This will push the children to the bottom
          children: [
            Expanded(child: AudioList()), // Expanded widget ensures the AudioList takes the remaining available space
            AudioRecorder(),
          ],
        ),
      ),
    );
  }
}