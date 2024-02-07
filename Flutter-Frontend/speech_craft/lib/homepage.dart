import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final soundRecorderAndPlayer = SoundRecorderAndPlayer();
  bool isRecording = false, isPlaying = false, isRecordingAvailable = false;
  late String? filePath;
  late AudioPlayer player;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
  }

  void _startPlaying(String fileString) {
    setState(() {
      isPlaying = true;
    });
    Source file = UrlSource(fileString);
    player.play(file);
  }

  void _stopPlaying() {
    setState(() {
      isPlaying = false;
    });
    player.stop();
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
                onPressed: () {
                  if (!isRecording && !isPlaying) {
                    print('Nonu: Recording Started.');
                    soundRecorderAndPlayer.toggleRecording();
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
                      filePath = await soundRecorderAndPlayer.toggleRecording();
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
                      togglePlaying(filePath!);
                      setState(() {
                        isPlaying = false;
                      });
                    } else {
                      print('Nonu: Playing Recording Started.');
                      togglePlaying(filePath!);
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
                  filePath = await soundRecorderAndPlayer.uploadAndPlay();
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
                  'Upload and Play',
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

class SoundRecorderAndPlayer {
  bool _recording = false, _playing = false;
  String _filePath = '', _appUid = '';

  void init(String arg) async {
    _appUid = arg;

    askMicPermission();
  }

  void dispose() {}

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

  bool isRecording() {
    return _recording;
  }

  Future<String> getFilePath() async {
    String fileName =
        'Recording-Varta-' + _appUid + '-' + randomAlphaNumeric(10) + '.wav';
    Directory directory;
    try {
      if (Platform.isAndroid) {
        directory = (await getExternalStorageDirectory())!;
        String newPath = "";
        List<String> paths = directory.path.split("/");
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != "Android") {
            newPath += "/" + folder;
          } else {
            break;
          }
        }
        newPath = newPath + "/Vaarta/Recordings";
        directory = Directory(newPath);
      } else {
        directory = await getTemporaryDirectory();
      }
      File saveFile = File(directory.path + "/$fileName");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        return saveFile.path;
      }
      return '';
    } catch (e) {
      print(e);
      return '';
    }
  }

  Future _startRecording() async {
    _filePath = await getFilePath();
    if (_filePath != '') {
      try {
        print("Nonu: Recording started - " + _recording.toString());
        FlutterSoundSystem.startRecording(_filePath);
      } catch (e) {
        print("Nonu: Recording Error - " + _recording.toString());
      }
    } else {
      _stopPlaying();
      print("Nonu: _filePath empty - " + _recording.toString());
    }
  }

  Future _stopRecording() async {
    try {
      await FlutterSoundSystem.stopRecording();
    } catch (e) {
      print("Nonu: Stop Recording Error - " + e.toString());
    }
  }

  Future<String> toggleRecording() async {
    if (!_recording) {
      _recording = true;
      _filePath = '';
      if (await Permission.storage.status == PermissionStatus.granted) {
        await _startRecording();
      } else {
        await Permission.storage.request();
      }
      return '';
    } else {
      _recording = false;
      await _stopRecording();
      return _filePath;
    }
  }

  bool isPlaying() {
    return _playing;
  }

  void _startPlaying(String fileString) {
    FlutterSoundSystem.playMedia(fileString);
  }

  void _stopPlaying() {
    FlutterSoundSystem.stopMedia();
  }

  Future<bool> togglePlaying(String fileString) async {
    if (_playing) {
      _startPlaying(fileString);
      return true;
    } else {
      _stopPlaying();
      return false;
    }
  }

  Future<String?> uploadAndPlay() async {
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
          final File sourceFile = File(file.path!);
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
}
