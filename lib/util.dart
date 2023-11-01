import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

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
    if (words.length <= 10) {
      return words.join(' ');
    } else {
      return words.take(10).join(' ');
    }
  }
  return "";
}

Future<void>  renameAllFilesWithBaseName(String path, String newBaseName) async {
  // Getting the directory of the given path
  Directory dir = Directory(path).parent;

  // Checking if the directory exists
  if (await dir.exists()) {
    // Listing all files in the directory
    await for (FileSystemEntity entity in dir.list()) {
      if (entity is File) {
        String fileExtension = entity.uri.pathSegments.last.split('.').last;
        String newFileName = '$newBaseName.$fileExtension';
        File newFile = File('${dir.path}/$newFileName');

        // Renaming the file
        await entity.rename(newFile.path);
        print('File renamed to: $newFileName');
      }
    }
  } else {
    print('Directory does not exist.');
  }
}


