import 'package:background_runtime/background_runtime.dart';
import 'package:flutter/material.dart';

class DownloadsPage extends StatefulWidget {
  final bool initialized;
  final Map<String, DownloadEvent> downloadEvents;
  final Map<String, DownloadState> downloadStates;
  final Future<String?> Function({
    required String url,
    required String destinationPath,
    bool saveToPublic,
  }) onStartDownload;
  final Future<void> Function(String taskId) onPause;
  final Future<void> Function(String taskId) onResume;
  final Future<void> Function(String taskId) onCancel;
  final List<String> logs;

  const DownloadsPage({
    super.key,
    required this.initialized,
    required this.downloadEvents,
    required this.downloadStates,
    required this.onStartDownload,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.logs,
  });

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _urlController = TextEditingController(
    text: 'https://github.com/flutter/flutter/archive/refs/heads/main.zip',
  );
  final _pathController =
      TextEditingController(text: '/tmp/background_runtime_download');
  bool _saveToPublic = false;

  @override
  void dispose() {
    _urlController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Text('New Download', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'File URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Save Path',
                      border: OutlineInputBorder(),
                      hintText: '/tmp/myfile.zip',
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Save to public Downloads'),
                    value: _saveToPublic,
                    onChanged: (v) => setState(() => _saveToPublic = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Start Download'),
                    onPressed: widget.initialized
                        ? () {
                            widget.onStartDownload(
                              url: _urlController.text.trim(),
                              destinationPath: _pathController.text.trim(),
                              saveToPublic: _saveToPublic,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (widget.downloadEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Active Downloads', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...widget.downloadEvents.entries.map((entry) {
              final event = entry.value;
              final state = event.state;
              final bytesReceived = event.bytesReceived;
              final totalBytes = event.totalBytes;
              final progressStr = bytesReceived != null && totalBytes != null
                  ? '${(bytesReceived / 1048576).toStringAsFixed(1)} MB / ${(totalBytes / 1048576).toStringAsFixed(1)} MB'
                  : null;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _iconForState(state),
                            size: 20,
                            color: _colorForState(state),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                event.url ?? '',
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ),
                        ],
                      ),
                      if (progressStr != null) ...[
                        const SizedBox(height: 4),
                        Text(progressStr, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: event.progress?.clamp(0.0, 1.0),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (state == DownloadState.downloading)
                            _SmallButton(
                              icon: Icons.pause,
                              label: 'Pause',
                              onPressed: () =>
                                  widget.onPause(event.taskId),
                            ),
                          if (state == DownloadState.paused)
                            _SmallButton(
                              icon: Icons.play_arrow,
                              label: 'Resume',
                              onPressed: () =>
                                  widget.onResume(event.taskId),
                            ),
                          if (state == DownloadState.downloading ||
                              state == DownloadState.paused)
                            const SizedBox(width: 8),
                          _SmallButton(
                            icon: Icons.cancel,
                            label: 'Cancel',
                            color: Colors.red,
                            onPressed: () =>
                                widget.onCancel(event.taskId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (widget.logs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Log', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...widget.logs.take(10).map(
              (log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(log,
                    style:
                        const TextStyle(fontSize: 10, fontFamily: 'monospace')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForState(DownloadState state) {
    switch (state) {
      case DownloadState.pending:
        return Icons.schedule;
      case DownloadState.downloading:
        return Icons.downloading;
      case DownloadState.paused:
        return Icons.pause_circle;
      case DownloadState.completed:
        return Icons.check_circle;
      case DownloadState.failed:
        return Icons.error;
      case DownloadState.cancelled:
        return Icons.cancel;
    }
  }

  Color _colorForState(DownloadState state) {
    switch (state) {
      case DownloadState.pending:
        return Colors.grey;
      case DownloadState.downloading:
        return Colors.blue;
      case DownloadState.paused:
        return Colors.orange;
      case DownloadState.completed:
        return Colors.green;
      case DownloadState.failed:
        return Colors.red;
      case DownloadState.cancelled:
        return Colors.grey;
    }
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const _SmallButton({
    required this.icon,
    required this.label,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}
