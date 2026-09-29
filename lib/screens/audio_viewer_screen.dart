import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const AudioViewerScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<AudioViewerScreen> createState() => _AudioViewerScreenState();
}

class _AudioViewerScreenState extends State<AudioViewerScreen> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.play(DeviceFileSource(widget.path));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack_rounded, size: 96, color: scheme.primary),
            const SizedBox(height: 32),
            Slider(
              value: progress,
              onChanged: (value) {
                final target = Duration(
                  milliseconds: (value * _duration.inMilliseconds).round(),
                );
                _player.seek(target);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(_position)),
                Text(_format(_duration)),
              ],
            ),
            const SizedBox(height: 24),
            IconButton(
              iconSize: 64,
              icon: Icon(
                _state == PlayerState.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              onPressed: () {
                if (_state == PlayerState.playing) {
                  _player.pause();
                } else {
                  _player.resume();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
