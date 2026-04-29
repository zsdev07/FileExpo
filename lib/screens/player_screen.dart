import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

class PlayerScreen extends StatefulWidget {
  final File audioFile;
  const PlayerScreen({super.key, required this.audioFile});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupPlayer();
  }

  void _setupPlayer() async {
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerStateChanged.listen((s) => setState(() => _playerState = s));
    
    await _audioPlayer.setSourceDeviceFile(widget.audioFile.path);
    _audioPlayer.play(DeviceFileSource(widget.audioFile.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              p.basename(widget.audioFile.path),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          Slider(
            min: 0,
            max: _duration.inMilliseconds.toDouble(),
            value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              _audioPlayer.seek(Duration(milliseconds: value.toInt()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(_duration)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 64,
                icon: Icon(_playerState == PlayerState.playing ? Icons.pause_circle : Icons.play_circle),
                onPressed: () {
                  if (_playerState == PlayerState.playing) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play(DeviceFileSource(widget.audioFile.path));
                  }
                },
              ),
              IconButton(
                iconSize: 48,
                icon: const Icon(Icons.stop_circle),
                onPressed: () => _audioPlayer.stop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
