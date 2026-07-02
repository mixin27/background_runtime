import 'package:background_runtime/background_runtime.dart';
import 'package:flutter/material.dart';

class LifecyclePage extends StatelessWidget {
  final List<RuntimeLifecycle> lifecycleEvents;
  final VoidCallback onClear;

  const LifecyclePage({
    super.key,
    required this.lifecycleEvents,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (lifecycleEvents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text('${lifecycleEvents.length} events',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  onPressed: onClear,
                ),
              ],
            ),
          ),
        Expanded(
          child: lifecycleEvents.isEmpty
              ? Center(
                  child: Text('No lifecycle events yet',
                      style: theme.textTheme.bodyMedium),
                )
              : ListView.builder(
                  itemCount: lifecycleEvents.length,
                  itemBuilder: (context, index) {
                    final event = lifecycleEvents[index];
                    final timeStr = event.timestamp
                        .toLocal()
                        .toString()
                        .substring(11, 19);
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _iconForEvent(event.event),
                        size: 20,
                        color: _colorForEvent(event.event),
                      ),
                      title: Text(
                        event.event.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Text(timeStr,
                          style: theme.textTheme.bodySmall),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _iconForEvent(RuntimeLifecycleEvent event) {
    switch (event) {
      case RuntimeLifecycleEvent.initialized:
        return Icons.play_arrow;
      case RuntimeLifecycleEvent.started:
        return Icons.play_circle;
      case RuntimeLifecycleEvent.paused:
        return Icons.pause;
      case RuntimeLifecycleEvent.resumed:
        return Icons.play_circle_outline;
      case RuntimeLifecycleEvent.stopped:
        return Icons.stop;
      case RuntimeLifecycleEvent.terminated:
        return Icons.cancel;
    }
  }

  Color _colorForEvent(RuntimeLifecycleEvent event) {
    switch (event) {
      case RuntimeLifecycleEvent.initialized:
        return Colors.green;
      case RuntimeLifecycleEvent.started:
        return Colors.blue;
      case RuntimeLifecycleEvent.paused:
        return Colors.orange;
      case RuntimeLifecycleEvent.resumed:
        return Colors.lightBlue;
      case RuntimeLifecycleEvent.stopped:
        return Colors.grey;
      case RuntimeLifecycleEvent.terminated:
        return Colors.red;
    }
  }
}
