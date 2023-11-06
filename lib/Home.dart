import 'package:flutter/material.dart';
import 'audio_record.dart';
import 'audio_list.dart';
import 'package:path_provider/path_provider.dart'; // Import the path_provider package
import 'dart:io';
import 'package:path/path.dart' as path;
import 'components/error_widget.dart';
import 'pages/auth_page.dart';
import 'searchbar.dart';
import 'util.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isDarkMode = false;
  String prompt = "";
  Map<File, String?> audioToTextMap = {};
  Map<File, String?> filterMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  _fetchAudios() async {
    audioToTextMap.clear(); // Clear the map first
    final appDir = await getApplicationDocumentsDirectory();
    final recordingDir = Directory(path.join(appDir.path));
    if (await recordingDir.exists()) {
      final entities = recordingDir.listSync();
      for (var entity in entities) {
        if (entity is File && path.extension(entity.path) == '.wav') {
          final jsonFile = File(entity.path.replaceFirst('.wav', '.json'));
          String? previewContent;
          if (await jsonFile.exists()) {
            String jsonString = await jsonFile.readAsString();
            previewContent = getPreviewFromJson(jsonString);
            debugPrint("Preview content: $previewContent");
          } else {
            previewContent = null;
          }
          setState(() {
            audioToTextMap[entity] = previewContent;
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
    Map<File, String?> filteredMap = Map.fromEntries(
      audioToTextMap.entries.where((entry) {
        String fileName = entry.key.uri.pathSegments.last;
        String? fileContent = entry.value;
        return fileName.contains(prompt) || (fileContent?.contains(prompt) ?? false);
      }),
    );
    setState(() {
      this.prompt = prompt;
      filterMap = filteredMap;
    });
    // print("filterPrompt: $filteredMap");

  }
  Future<void> _onRefresh() async {
    debugPrint("Refresh");
    await _fetchAudios();
    setState(() {});
  }

@override
Widget build(BuildContext context) {
  final ThemeData themeData = ThemeData(
    useMaterial3: true,
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
  );
  // Define the text color based on the theme's brightness
  Color textColor = isDarkMode ? Colors.white : Colors.black;
  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return CustomError(errorDetails: errorDetails);
  };
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: themeData,
    home: Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              foregroundColor: Colors.lightBlue,
              expandedHeight: 100.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Voice Notes", style: TextStyle(color: textColor, )),
              ),
              // actions: <Widget>[
              //   Builder(
              //     builder: (BuildContext context) {
              //       return IconButton(
              //         icon: const Icon(Icons.person, color: Colors.blue),
              //         onPressed: () {
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(builder: (context) => const AuthPage()),
              //           );
              //         },
              //       );
              //     },
              //   ),
              // ],
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  SearchBarApp(
                    toggleDarkMode: _toggleDarkMode,
                    setPrompt: _setPrompt,
                  ),
                  // if searchbar is not empty, show filtered list
                  AudioList(
                    audioToTextMap: prompt !='' ? filterMap: audioToTextMap,
                    onRefresh: _onRefresh,
                    ), 
                  
                ]
              ),
            ),
          ],
          
          ),
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
