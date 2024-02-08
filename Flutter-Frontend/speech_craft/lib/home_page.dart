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
import 'package:path/path.dart' as path;
import 'package:speech_craft/components/neu_box.dart';
import 'package:speech_craft/enhance_voice.dart';

import 'audio_list_page.dart';

// import 'package:just_audio/just_audio.dart';

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

      var response = await request.send();

      if (response.statusCode == 200) {
        // Get the response body as bytes
        List<int> responseBodyBytes = await response.stream.toBytes();

        // Get the app directory path
        String appDocPath = (await getApplicationDocumentsDirectory()).path;

        // Write the response bytes to a zip file
        File zipFile = File('$appDocPath/separated_sources.zip');
        await zipFile.writeAsBytes(responseBodyBytes);

        // Unzip the file
        var archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());

        // Create a list to store the paths of the extracted audio files
        List<String> audioFilePaths = [];

        // Extract and save the audio files
        for (var file in archive) {
          if (file.isFile) {
            String filePath = '$appDocPath/${file.name}';
            File outFile = File(filePath);
            await outFile.writeAsBytes(file.content);
            audioFilePaths.add(filePath);
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioListPage(audioFiles: audioFilePaths),
          ),
        );
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> enhanceSpeech() async {
    try {
      File audioFile = File(_filePath!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${APIConstants.baseUrl}/get/enhance'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: 'audio.wav',
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        List<int> responseBodyBytes = await response.stream.toBytes();

        var documentsDir = await getApplicationDocumentsDirectory();
        var filePath = path.join(documentsDir.path, 'enhanced_audio.wav');
        File audio = File(filePath);
        await audio.writeAsBytes(responseBodyBytes);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhanceAudio(
              audioFilePath: filePath,
            ),
          ),
        );
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: NeuBox(
                          child: IconButton(
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
                              icon: Icon(Icons.record_voice_over_rounded))),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: NeuBox(
                          child: IconButton(
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
                              icon: Icon(Icons.stop_rounded))),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: NeuBox(
                          child: IconButton(
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
                              icon: Icon(Icons.play_arrow_rounded))),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: NeuBox(
                          child: IconButton(
                              onPressed: () async {
                                _filePath = (await upload())!;
                                setState(() {
                                  isRecordingAvailable = true;
                                });
                              },
                              icon: Icon(Icons.upload_file_rounded))),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: NeuBox(
                          child: IconButton(
                              onPressed: () async {
                                await separateSpeech();
                              },
                              icon: Icon(Icons.join_full_rounded))),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: NeuBox(
                          child: IconButton(
                              onPressed: () async {
                                await enhanceSpeech();
                              },
                              icon:
                                  Icon(Icons.enhance_photo_translate_rounded))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
