import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:intl/intl.dart';

bool doesFileWithDifferentExtensionExist(String path, String newExtension) {
  // Get the directory of the file
  String dirName = p.dirname(path);
  
  // Get the file name without the extension
  String fileNameWithoutExtension = p.basenameWithoutExtension(path);

  // Create the new file path with the new extension
  String newPath = p.join(dirName, '$fileNameWithoutExtension$newExtension');

  // Check if the file exists
  return File(newPath).existsSync();
}

String fileWithDiffExtension(String path, String newExtension) {
    // Get the directory of the file
  String dirName = p.dirname(path);
  
  // Get the file name without the extension
  String fileNameWithoutExtension = p.basenameWithoutExtension(path);

  // Create the new file path with the new extension
  String newPath = p.join(dirName, '$fileNameWithoutExtension$newExtension');
  return newPath;
}

void saveJsonToFile(String jsonStr, String path) async {
  final file = File(path);

  // Check if the directory exists, if not create it
  final directory = file.parent;
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  // Write the JSON string to the file
  await file.writeAsString(jsonStr);
}

String getPreviewFromJson(String jsonString) {
  final decodedJson = jsonDecode(jsonString) as List<dynamic>;
  if (decodedJson.isNotEmpty && decodedJson[0]['insert'] != null) {
    String insertText = decodedJson[0]['insert'];
    List<String> words = insertText.split(' ');
    if (words.length <= 30) {
      return words.join(' ');
    } else {
      return words.take(10).join(' ');
    }
  }
  return "";
}

Future<void> renameFilesWithBaseName(String path, String newBaseName) async {
  // Get the directory of the given path and the base name of the file
  var directory = Directory(path).parent;
  var oldBaseName = p.basenameWithoutExtension(path);

  // List all files in the directory
  List<FileSystemEntity> files = await directory.list().toList();

  // Filter out files that have the same base name
  var filesToRename = files.where((file) {
    return p.basenameWithoutExtension(file.path) == oldBaseName;
  }).toList();
  debugPrint("filesToRename: $filesToRename");
  // Rename each filtered file with the new base name while preserving the extension
  for (var file in filesToRename) {
    var fileExtension = p.extension(file.path);
    var newPath = p.join(directory.path, '$newBaseName$fileExtension');
    await file.rename(newPath);
  }
}

Future<String> getFileCreationDate(String filePath) async {
  File file = File(filePath);

  try {
    // Get the file's stat
    FileStat fileStat = await file.stat();

    // Get the creation date
    DateTime creationDate = fileStat.modified;

    // Format the date
    String formattedDate = DateFormat('MMM d').format(creationDate);

    return formattedDate;
  } catch (e) {
    print('Error getting file creation date: $e');
    return 'Unknown Date';
  }
}