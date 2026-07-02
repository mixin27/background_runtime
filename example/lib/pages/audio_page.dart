import 'package:background_runtime/background_runtime.dart';
import 'package:flutter/material.dart';

class AudioPage extends StatefulWidget {
  final bool initialized;
  final PlayerState playerState;
  final Future<void> Function({
    required Uri source,
    required String title,
    String? artist,
  }) onPlay;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onStop;
  final Future<void> Function(Duration position) onSeek;

  const AudioPage({
    super.key,
    required this.initialized,
    required this.playerState,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSeek,
  });

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final _urlController = TextEditingController(
    text: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  );
  final _titleController = TextEditingController(text: 'SoundHelix Song');
  final _artistController = TextEditingController(text: 'SoundHelix');

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ps = widget.playerState;
    final isPlaying = ps.state == PlaybackState.playing;
    final duration = ps.duration?.inMilliseconds ?? 0;
    final position = ps.position?.inMilliseconds ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Audio Source', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Audio URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://...mp3',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      labelText: 'Artist',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.music_note),
                    label: const Text('Play'),
                    onPressed: widget.initialized
                        ? () {
                            final uri =
                                Uri.tryParse(_urlController.text.trim());
                            if (uri != null) {
                              widget.onPlay(
                                source: uri,
                                title: _titleController.text.trim(),
                                artist: _artistController.text.trim(),
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Now Playing', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        isPlaying ? Icons.play_circle : Icons.pause_circle,
                        size: 48,
                        color: isPlaying ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ps.state.name,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track: ${ps.trackId ?? 'none'}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Position: ${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (duration > 0) ...[
                    const SizedBox(height: 12),
                    Slider(
                      value: position.toDouble().clamp(0, duration.toDouble()),
                      max: duration.toDouble().clamp(1, double.infinity),
                      onChanged: (_) {},
                      onChangeEnd: (v) {
                        widget.onSeek(Duration(milliseconds: v.toInt()));
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPlaying)
                        IconButton.filled(
                          icon: const Icon(Icons.pause),
                          onPressed: widget.onPause,
                        )
                      else
                        IconButton.filled(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: widget.onResume,
                        ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: widget.onStop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int millis) {
    final totalSeconds = millis ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
