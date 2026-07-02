/// The type of runtime lifecycle event.
enum RuntimeLifecycleEvent {
  initialized,
  started,
  paused,
  resumed,
  stopped,
  terminated;

  static RuntimeLifecycleEvent fromString(String value) {
    return RuntimeLifecycleEvent.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RuntimeLifecycleEvent.terminated,
    );
  }
}

/// An event representing a change in the runtime lifecycle.
final class RuntimeLifecycle {
  final RuntimeLifecycleEvent event;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const RuntimeLifecycle({
    required this.event,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  static RuntimeLifecycle fromMap(Map<String, dynamic> map) {
    return RuntimeLifecycle(
      event: RuntimeLifecycleEvent.fromString(map['event'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeLifecycle &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          timestamp == other.timestamp &&
          data == other.data;

  @override
  int get hashCode => Object.hash(event, timestamp, data);

  @override
  String toString() =>
      'RuntimeLifecycle(event: $event, timestamp: $timestamp)';
}
