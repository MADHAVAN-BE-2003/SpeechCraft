import 'dart:io';
import 'package:flutter/material.dart';

class AudioListPage extends StatefulWidget {
  final List<File> audioFiles;

  AudioListPage({required this.audioFiles});

  @override
  _AudioListPageState createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Extracted Audio Files'),
      ),
      body: ListView.builder(
        itemCount: widget.audioFiles.length,
        itemBuilder: (context, index) {
          File audioFile = widget.audioFiles[index];
          return ListTile(
            title: Text('Audio File ${index + 1}'),
            subtitle: Text('Size: ${audioFile.lengthSync()} bytes'),
          );
        },
      ),
    );
  }
}
