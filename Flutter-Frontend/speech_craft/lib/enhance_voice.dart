import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class EnhanceAudio extends StatefulWidget {
  final String audioFilePath;

  EnhanceAudio({required this.audioFilePath});

  @override
  _EnhanceAudioState createState() => _EnhanceAudioState();
}

class _EnhanceAudioState extends State<EnhanceAudio> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String? _currentPlayingFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String audioFilePath = widget.audioFilePath;
    String fileName = audioFilePath.split('/').last;
    File audioFile = File(audioFilePath);
    int fileSize = audioFile.lengthSync();

    return Scaffold(
      appBar: AppBar(
        title: Text('Extracted Audio File'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(fileName),
            subtitle: Text('Size: $fileSize bytes'),
            trailing: IconButton(
              icon: Icon(_isPlaying && _currentPlayingFilePath == audioFilePath
                  ? Icons.pause
                  : Icons.play_arrow),
              onPressed: () => _playAudio(audioFilePath),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playAudio(String filePath) async {
    if (_isPlaying && _currentPlayingFilePath == filePath) {
      // Stop playing if already playing the same file
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPlayingFilePath = null;
      });
    } else {
      // Start playing the selected file
      await _audioPlayer.play(UrlSource(filePath));
      setState(() {
        _isPlaying = true;
        _currentPlayingFilePath = filePath;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
