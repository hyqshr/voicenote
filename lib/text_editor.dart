import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:path_provider/path_provider.dart';

class QuillEditorWidget extends StatefulWidget {
  final String source;
  final VoidCallback refreshCallBack;

  const QuillEditorWidget({
      super.key,
      required this.source,
      required this.refreshCallBack,
    });

  @override
  _QuillEditorWidgetState createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  QuillController? _controller;
  String? _originalContent;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  _loadContent() async {
    await _updateOriginalContent();
    if (_originalContent != null) {
      List<dynamic> jsonString = jsonDecode(_originalContent!);
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

  Future<void> _updateOriginalContent() async {
    File quillJsonFile = File(widget.source);
    if (await quillJsonFile.exists()) {
      _originalContent = await quillJsonFile.readAsString();
    }
  }

  Future<bool> _isContentChanged() async {
    await _updateOriginalContent(); // Update _originalContent with latest file content
    if (_controller == null || _originalContent == null) return false;

    var currentContent = jsonEncode(_controller!.document.toDelta().toJson());
    debugPrint("Current content: $currentContent");
    debugPrint("Original content: $_originalContent");

    return _originalContent != currentContent;
  }
  
  Future<bool> _onBackPressed() async {
    if (await _isContentChanged()) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Unsaved Changes'),
              content: Text('You have unsaved changes. Do you want to save them before exiting?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _saveContent();
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Save and Exit'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Exit Without Saving'),
                ),
              ],
            ),
          ) ?? false;
    }
    return true;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _onBackPressed()) {
              widget.refreshCallBack();
              Navigator.of(context).pop();
            }
          },
        ), 
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
