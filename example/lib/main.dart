import 'dart:async';

import 'package:background_runtime/background_runtime.dart';
import 'package:flutter/material.dart';

import 'pages/audio_page.dart';
import 'pages/downloads_page.dart';
import 'pages/init_page.dart';
import 'pages/lifecycle_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BackgroundRuntimeExampleApp());
}

class BackgroundRuntimeExampleApp extends StatelessWidget {
  const BackgroundRuntimeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Runtime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  bool _initialized = false;
  BackgroundRuntimeConfig _config = const BackgroundRuntimeConfig();
  final Map<String, DownloadEvent> _downloadEvents = {};
  final Map<String, DownloadState> _downloadStates = {};
  PlayerState _playerState = const PlayerState(state: PlaybackState.idle);
  final List<RuntimeLifecycle> _lifecycleEvents = [];
  final List<String> _logs = [];

  StreamSubscription<DownloadEvent>? _downloadSub;
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<RuntimeLifecycle>? _lifecycleSub;

  @override
  void dispose() {
    _downloadSub?.cancel();
    _playerSub?.cancel();
    _lifecycleSub?.cancel();
    BackgroundRuntime.shutdown();
    super.dispose();
  }

  void addLog(String message) {
    setState(() {
      _logs.insert(0,
          '[${DateTime.now().toLocal().toString().substring(11, 19)}] $message');
    });
  }

  Future<void> initialize() async {
    try {
      await BackgroundRuntime.initialize(config: _config);
      setState(() => _initialized = true);
      addLog('Initialized');
      _subscribeToStreams();
    } catch (e) {
      addLog('Init failed: $e');
    }
  }

  void _subscribeToStreams() {
    _downloadSub?.cancel();
    _downloadSub = BackgroundRuntime.observeDownloads().listen((event) {
      setState(() {
        _downloadEvents[event.taskId] = event;
        _downloadStates[event.taskId] = event.state;
      });
      addLog('Download ${event.taskId}: ${event.state.name}');
    });

    _playerSub?.cancel();
    _playerSub = BackgroundRuntime.observePlayer().listen((state) {
      setState(() => _playerState = state);
      addLog('Player: ${state.state.name}');
    });

    _lifecycleSub?.cancel();
    _lifecycleSub = BackgroundRuntime.observeLifecycle().listen((event) {
      setState(() => _lifecycleEvents.insert(0, event));
      addLog('Lifecycle: ${event.event.name}');
    });
  }

  Future<String?> startDownload({
    required String url,
    required String destinationPath,
    bool saveToPublic = false,
  }) async {
    if (!_initialized) {
      addLog('Error: Not initialized');
      return null;
    }
    try {
      final request = DownloadRequest(
        url: url,
        destinationPath: destinationPath,
        saveToPublic: saveToPublic,
      );
      final taskId = await BackgroundRuntime.download(request);
      addLog('Started download: $taskId');
      return taskId;
    } catch (e) {
      addLog('Download failed: $e');
      return null;
    }
  }

  Future<void> pauseDownload(String taskId) async {
    try {
      await BackgroundRuntime.pause(taskId);
      addLog('Paused: $taskId');
    } catch (e) {
      addLog('Pause failed: $e');
    }
  }

  Future<void> resumeDownload(String taskId) async {
    try {
      await BackgroundRuntime.resume(taskId);
      addLog('Resumed: $taskId');
    } catch (e) {
      addLog('Resume failed: $e');
    }
  }

  Future<void> cancelDownload(String taskId) async {
    try {
      await BackgroundRuntime.cancel(taskId);
      _downloadEvents.remove(taskId);
      _downloadStates.remove(taskId);
      addLog('Cancelled: $taskId');
    } catch (e) {
      addLog('Cancel failed: $e');
    }
  }

  Future<void> playAudio({
    required Uri source,
    String title = 'Example Track',
    String? artist,
  }) async {
    if (!_initialized) {
      addLog('Error: Not initialized');
      return;
    }
    try {
      final track = AudioTrack(
        id: 'example-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        artist: artist,
        source: source,
      );
      await BackgroundRuntime.play(track);
      addLog('Playing: $source');
    } catch (e) {
      addLog('Play failed: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await BackgroundRuntime.pauseAudio();
      addLog('Audio paused');
    } catch (e) {
      addLog('Pause failed: $e');
    }
  }

  Future<void> resumeAudio() async {
    try {
      await BackgroundRuntime.resumeAudio();
      addLog('Audio resumed');
    } catch (e) {
      addLog('Resume failed: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await BackgroundRuntime.stop();
      addLog('Audio stopped');
    } catch (e) {
      addLog('Stop failed: $e');
    }
  }

  Future<void> seekAudio(Duration position) async {
    try {
      await BackgroundRuntime.seek(position);
      addLog('Seek: ${position.inMilliseconds}ms');
    } catch (e) {
      addLog('Seek failed: $e');
    }
  }

  Future<void> shutdown() async {
    _downloadSub?.cancel();
    _playerSub?.cancel();
    _lifecycleSub?.cancel();
    await BackgroundRuntime.shutdown();
    setState(() {
      _initialized = false;
      _downloadEvents.clear();
      _downloadStates.clear();
      _playerState = const PlayerState(state: PlaybackState.idle);
    });
    addLog('Shutdown complete');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Background Runtime'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Init'),
              Tab(icon: Icon(Icons.download), text: 'Downloads'),
              Tab(icon: Icon(Icons.music_note), text: 'Audio'),
              Tab(icon: Icon(Icons.list), text: 'Log'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InitPage(
              initialized: _initialized,
              config: _config,
              onConfigChanged: (c) => setState(() => _config = c),
              onInitialize: initialize,
              onShutdown: shutdown,
            ),
            DownloadsPage(
              initialized: _initialized,
              downloadEvents: _downloadEvents,
              downloadStates: _downloadStates,
              onStartDownload: startDownload,
              onPause: pauseDownload,
              onResume: resumeDownload,
              onCancel: cancelDownload,
              logs: _logs,
            ),
            AudioPage(
              initialized: _initialized,
              playerState: _playerState,
              onPlay: playAudio,
              onPause: pauseAudio,
              onResume: resumeAudio,
              onStop: stopAudio,
              onSeek: seekAudio,
            ),
            LifecyclePage(
              lifecycleEvents: _lifecycleEvents,
              onClear: () => setState(() => _lifecycleEvents.clear()),
            ),
          ],
        ),
      ),
    );
  }
}
