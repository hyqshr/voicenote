import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';

class QuillEditorWidget extends StatefulWidget {
  final String source;

  const QuillEditorWidget({
      super.key,
      required this.source,
    });

  @override
  _QuillEditorWidgetState createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  QuillController? _controller;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  _loadContent() async {
    File quillJsonFile = File(widget.source);
    if (await quillJsonFile.exists()) {
      // raw text exists, load from raw text
      String content = await quillJsonFile.readAsString();
      List<dynamic> jsonString = jsonDecode(content);
      setState(() {
        _controller = QuillController(
          document: Document.fromJson(jsonString),
          selection: TextSelection.collapsed(offset: 1),
        );
      });

    } else {
      setState(() {
        _controller = QuillController.basic();
      });
    }
  }
  void _saveContent() async{
    var json = jsonEncode(_controller!.document.toDelta().toJson());
    debugPrint("Content to save: $json");
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${widget.source}';

    // Save the content to the file
    final file = File(filePath);
    await file.writeAsString(json);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller==null) {
      return const CircularProgressIndicator(); // Show a loader till _controller is initialized
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Save button
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Implement your save functionality here
              _saveContent();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: QuillEditor(
              controller: _controller!,
              scrollController: ScrollController(),
              scrollable: true,
              focusNode: FocusNode(),
              autoFocus: false,
              readOnly: false,
              expands: false,
              padding: EdgeInsets.all(10),
            ),
          ),
          QuillToolbar.basic(controller: _controller!) // Basic toolbar
        ],
      ),
    );
  }
}
