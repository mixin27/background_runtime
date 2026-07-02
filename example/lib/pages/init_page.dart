import 'package:background_runtime/background_runtime.dart';
import 'package:flutter/material.dart';

class InitPage extends StatelessWidget {
  final bool initialized;
  final BackgroundRuntimeConfig config;
  final ValueChanged<BackgroundRuntimeConfig> onConfigChanged;
  final VoidCallback onInitialize;
  final VoidCallback onShutdown;

  const InitPage({
    super.key,
    required this.initialized,
    required this.config,
    required this.onConfigChanged,
    required this.onInitialize,
    required this.onShutdown,
  });

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
                  Text('Configuration', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Enable Downloads'),
                    value: config.enableDownloads,
                    onChanged: (v) =>
                        onConfigChanged(config.copyWith(enableDownloads: v)),
                  ),
                  CheckboxListTile(
                    title: const Text('Enable Audio'),
                    value: config.enableAudio,
                    onChanged: (v) =>
                        onConfigChanged(config.copyWith(enableAudio: v)),
                  ),
                  CheckboxListTile(
                    title: const Text('Enable Notifications'),
                    value: config.enableNotifications,
                    onChanged: (v) =>
                        onConfigChanged(config.copyWith(enableNotifications: v)),
                  ),
                  CheckboxListTile(
                    title: const Text('Keep Alive (Foreground Service)'),
                    subtitle: const Text('Android only'),
                    value: config.enableForegroundService,
                    onChanged: (v) => onConfigChanged(
                        config.copyWith(enableForegroundService: v)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Initialize'),
                          onPressed: initialized ? null : onInitialize,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Shutdown'),
                          onPressed: initialized ? onShutdown : null,
                        ),
                      ),
                    ],
                  ),
                  if (initialized)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text('Initialized',
                              style: TextStyle(color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
