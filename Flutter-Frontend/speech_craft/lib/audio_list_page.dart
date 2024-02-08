import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioListPage extends StatefulWidget {
  final List<String> audioFiles;

  AudioListPage({required this.audioFiles});

  @override
  _AudioListPageState createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Extracted Audio Files'),
      ),
      body: ListView.builder(
        itemCount: widget.audioFiles.length,
        itemBuilder: (context, index) {
          String audioFilePath = widget.audioFiles[index];
          String fileName = audioFilePath.split('/').last;
          File audioFile = File(audioFilePath);
          int fileSize = audioFile.lengthSync();

          return ListTile(
            title: Text(fileName),
            subtitle: Text('Size: $fileSize bytes'),
            trailing: IconButton(
              icon: Icon(_isPlaying && _currentPlayingFilePath == audioFilePath
                  ? Icons.pause
                  : Icons.play_arrow),
              onPressed: () => _playAudio(audioFilePath),
            ),
          );
        },
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
