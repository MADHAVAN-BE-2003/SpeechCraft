import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_craft/api_constants.dart';

import 'audio_list_page.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isRecording = false,
      isPlaying = false,
      isRecordingAvailable = false,
      _recording = false;
  String? _filePath = "";
  late Record recorder;
  late AudioPlayer player;
  String _localZipFileName = 'images.zip';

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    recorder = Record();
    askMicPermission();
  }

  @override
  void dispose() {
    super.dispose();
    recorder.dispose(); // Dispose of the recorder
    player.dispose(); // Dispose of the player
  }

  Future<File> _downloadFile(Uri url, String fileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    var file = File('$appDocPath/$fileName');
    var req = await http.Client().post(url);
    return file.writeAsBytes(req.bodyBytes);
  }

  Future<void> _downloadZip(Uri _zipPath) async {
    var zippedFile = await _downloadFile(_zipPath, _localZipFileName);
    await unarchiveAndSave(zippedFile);
  }

  unarchiveAndSave(var zippedFile) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    List<File> audioFiles = [];
    Uint8List bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$appDocPath/${file.name}';
      if (file.isFile) {
        var outFile = File(fileName);
        //print('File:: ' + outFile.path);
        audioFiles.add(outFile);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioListPage(audioFiles: audioFiles),
      ),
    );
  }

  Future<void> askMicPermission() async {
    var statusMicrophone = await Permission.microphone.status;
    if (statusMicrophone != PermissionStatus.granted) {
      await Permission.microphone.request();
    }
    askStoragePermission();
  }

  Future<void> askStoragePermission() async {
    var statusStorage = await Permission.storage.status;
    if (statusStorage != PermissionStatus.granted) {
      await Permission.storage.request();
    }
  }

  Future _startRecording() async {
    if (_filePath == '') {
      try {
        print("Nonu: Recording started - " + _recording.toString());
        await recorder.start();
      } catch (e) {
        print("Nonu: Recording Error - " + _recording.toString());
      }
    } else {
      await _stopPlaying();
      print("Nonu: _filePath empty - " + _recording.toString());
    }
  }

  Future _stopRecording() async {
    try {
      String? path = await recorder.stop();
      setState(() {
        _filePath = path;
      });
    } catch (e) {
      print("Nonu: Stop Recording Error - " + e.toString());
    }
  }

  Future<void> _startPlaying(String fileString) async {
    setState(() {
      isPlaying = true;
    });
    Source file = UrlSource(fileString);
    await player.play(file);
  }

  Future<void> _stopPlaying() async {
    setState(() {
      isPlaying = false;
    });
    await player.stop();
  }

  Future<bool> togglePlaying(String fileString) async {
    if (isPlaying) {
      _startPlaying(fileString);
      return true;
    } else {
      _stopPlaying();
      return false;
    }
  }

  Future<String?> upload() async {
    if (!_recording) {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['wav', 'mp4', 'm4a'],
        );

        if (result != null) {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String destFilePath = '${appDocDir.path}/uploaded_audio.wav';

          PlatformFile file = result.files.first;
          final File sourceFile = await File(file.path!);
          final File destFile = await sourceFile.copy(destFilePath);

          return destFile.path;
        } else {
          // User canceled the picker
          return null;
        }
      } catch (e) {
        print('Error uploading and playing: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> toggleRecording() async {
    try {
      if (!_recording) {
        _filePath = "";
        _recording = true;
        if (await Permission.storage.status == PermissionStatus.granted) {
          await _startRecording();
        } else {
          await Permission.storage.request();
        }
      } else {
        _recording = false;
        await _stopRecording();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> separateSpeech() async {
    try {
      File audioFile = File(_filePath!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${APIConstants.baseUrl}/get/separate'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: 'audio.wav',
      ));

      _downloadZip(request.url);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sound System'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  if (!isRecording && !isPlaying) {
                    print('Nonu: Recording Started.');
                    await toggleRecording();
                    setState(() {
                      isRecording = true;
                      isRecordingAvailable = false;
                    });
                  }
                },
                style: ButtonStyle(
                  backgroundColor: isRecording || isPlaying
                      ? MaterialStateProperty.all<Color>(Colors.blueGrey)
                      : MaterialStateProperty.all<Color>(Colors.green),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(10)),
                ),
                child: const Text(
                  'Start Recording',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 11.0, bottom: 11.0),
                child: TextButton(
                  onPressed: () async {
                    if (isRecording) {
                      await toggleRecording();
                      print('Nonu: Recording Done.');
                      setState(() {
                        isRecording = false;
                        isRecordingAvailable = true;
                      });
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: isRecording
                        ? MaterialStateProperty.all<Color>(Colors.green)
                        : MaterialStateProperty.all<Color>(Colors.blueGrey),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.all(10)),
                  ),
                  child: const Text(
                    'Stop Recording',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (isRecordingAvailable && !isRecording) {
                    if (isPlaying) {
                      print('Nonu: Playing Recording Stopped.');
                      print(_filePath);
                      togglePlaying(_filePath!);
                      setState(() {
                        isPlaying = false;
                      });
                    } else {
                      print('Nonu: Playing Recording Started.');
                      togglePlaying(_filePath!);
                      setState(() {
                        isPlaying = true;
                      });
                    }
                  }
                },
                style: ButtonStyle(
                  backgroundColor: isRecordingAvailable && !isRecording
                      ? MaterialStateProperty.all<Color>(Colors.green)
                      : MaterialStateProperty.all<Color>(Colors.blueGrey),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(10)),
                ),
                child: const Text(
                  'Play Recording',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  _filePath = (await upload())!;
                  setState(() {
                    isRecordingAvailable = true;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: !isRecording
                      ? MaterialStateProperty.all<Color>(Colors.green)
                      : MaterialStateProperty.all<Color>(Colors.blueGrey),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(10)),
                ),
                child: const Text(
                  'Upload',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await separateSpeech();
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(10)),
                ),
                child: const Text(
                  'Separate Speech',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
