import Cocoa
import FlutterMacOS
import AVFoundation

public class BackgroundRuntimeMacosPlugin: NSObject, FlutterPlugin {
    private let persistence = PersistenceManager()
    private lazy var notificationManager: NotificationManager = {
        NotificationManager()
    }()
    private lazy var downloadManager: DownloadManager = {
        DownloadManager(persistence: persistence, notificationManager: notificationManager)
    }()
    private lazy var audioManager: AudioManager = {
        AudioManager(persistence: persistence)
    }()

    private var lifecycleEventSink: FlutterEventSink?

    private var methodChannel: FlutterMethodChannel?
    private var downloadEventChannel: FlutterEventChannel?
    private var playerStateChannel: FlutterEventChannel?
    private var lifecycleEventChannel: FlutterEventChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = BackgroundRuntimeMacosPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "dev.mixin27.background_runtime/method",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        instance.methodChannel = methodChannel

        let downloadEventChannel = FlutterEventChannel(
            name: "dev.mixin27.background_runtime/downloadEvents",
            binaryMessenger: registrar.messenger
        )
        downloadEventChannel.setStreamHandler(instance.downloadManager)
        instance.downloadEventChannel = downloadEventChannel

        let playerStateChannel = FlutterEventChannel(
            name: "dev.mixin27.background_runtime/playerState",
            binaryMessenger: registrar.messenger
        )
        playerStateChannel.setStreamHandler(instance.audioManager)
        instance.playerStateChannel = playerStateChannel

        let lifecycleEventChannel = FlutterEventChannel(
            name: "dev.mixin27.background_runtime/lifecycleEvents",
            binaryMessenger: registrar.messenger
        )
        lifecycleEventChannel.setStreamHandler(instance)
        instance.lifecycleEventChannel = lifecycleEventChannel

        instance.downloadManager.setupSession()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result)
        case "startDownload":
            handleStartDownload(call, result)
        case "pauseDownload":
            handlePauseDownload(call, result)
        case "resumeDownload":
            handleResumeDownload(call, result)
        case "cancelDownload":
            handleCancelDownload(call, result)
        case "playAudio":
            handlePlayAudio(call, result)
        case "pauseAudio":
            handlePauseAudio(result)
        case "resumeAudio":
            handleResumeAudio(result)
        case "stopAudio":
            handleStopAudio(result)
        case "seekAudio":
            handleSeekAudio(call, result)
        case "shutdown":
            handleShutdown(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Initialize

    private func handleInitialize(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let configMap = args["config"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing config", details: nil))
            return
        }

        let enableNotifications = configMap["enableNotifications"] as? Bool ?? false
        let enableAudio = configMap["enableAudio"] as? Bool ?? true
        let keepAlive = configMap["keepAlive"] as? Bool ?? true
        let autoResume = configMap["autoResume"] as? Bool ?? true

        let persistedConfig = PersistedConfig(
            enableDownloads: configMap["enableDownloads"] as? Bool ?? true,
            enableAudio: enableAudio,
            enableNotifications: enableNotifications,
            keepAlive: keepAlive,
            autoResume: autoResume
        )
        persistence.saveConfig(persistedConfig)

        if enableNotifications {
            notificationManager.requestPermission()
        }

        if enableAudio {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                // Audio session setup is best-effort on macOS
            }
        }

        if autoResume {
            restoreState()
        }

        emitLifecycleEvent(state: "INITIALIZED")
        result(nil)
    }

    private func restoreState() {
        let activeDownloads = persistence.loadActiveDownloads()
        for download in activeDownloads {
            let request: [String: Any] = [
                "url": download.url,
                "destinationPath": download.destinationPath,
                "headers": download.headersJson ?? "",
                "saveToPublic": download.saveToPublic,
            ]
            persistence.removeDownload(taskId: download.taskId)
            downloadManager.startDownload(request: request, completion: { _ in })
        }

        if let persistedTrack = persistence.loadAudioTrack(),
           persistedTrack.state == "PLAYING" || persistedTrack.state == "PAUSED" {
            let track: [String: Any] = [
                "id": persistedTrack.trackId ?? "",
                "title": persistedTrack.title ?? "",
                "artist": persistedTrack.artist ?? "",
                "album": persistedTrack.album ?? "",
                "source": persistedTrack.source ?? "",
                "durationMillis": persistedTrack.durationMillis ?? 0,
            ]
            audioManager.playAudio(track: track) { [weak self] _ in
                if persistedTrack.state == "PAUSED" {
                    self?.audioManager.pauseAudio { _ in }
                }
                if persistedTrack.positionMillis > 0 {
                    self?.audioManager.seekAudio(positionMillis: persistedTrack.positionMillis) { _ in }
                }
            }
        }
    }

    // MARK: - Download

    private func handleStartDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let request = args["request"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing request", details: nil))
            return
        }
        downloadManager.startDownload(request: request, completion: result)
    }

    private func handlePauseDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let taskId = args["taskId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing taskId", details: nil))
            return
        }
        downloadManager.pauseDownload(taskId: taskId, completion: result)
    }

    private func handleResumeDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let taskId = args["taskId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing taskId", details: nil))
            return
        }
        downloadManager.resumeDownload(taskId: taskId, completion: result)
    }

    private func handleCancelDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let taskId = args["taskId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing taskId", details: nil))
            return
        }
        downloadManager.cancelDownload(taskId: taskId, completion: result)
    }

    // MARK: - Audio

    private func handlePlayAudio(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let track = args["track"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing track", details: nil))
            return
        }
        audioManager.playAudio(track: track, completion: result)
    }

    private func handlePauseAudio(_ result: @escaping FlutterResult) {
        audioManager.pauseAudio(completion: result)
    }

    private func handleResumeAudio(_ result: @escaping FlutterResult) {
        audioManager.resumeAudio(completion: result)
    }

    private func handleStopAudio(_ result: @escaping FlutterResult) {
        audioManager.stopAudio(completion: result)
    }

    private func handleSeekAudio(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let positionMillis = args["positionMillis"] as? Int64 else {
            result(nil)
            return
        }
        audioManager.seekAudio(positionMillis: positionMillis, completion: result)
    }

    // MARK: - Shutdown

    private func handleShutdown(_ result: @escaping FlutterResult) {
        audioManager.shutdown()
        downloadManager.shutdown()

        methodChannel?.setMethodCallHandler(nil)
        downloadEventChannel?.setStreamHandler(nil)
        playerStateChannel?.setStreamHandler(nil)
        lifecycleEventChannel?.setStreamHandler(nil)

        emitLifecycleEvent(state: "SHUTDOWN")
        result(nil)
    }

    // MARK: - Lifecycle Events

    private func emitLifecycleEvent(state: String) {
        lifecycleEventSink?(["state": state])
    }
}

// MARK: - FlutterStreamHandler (for lifecycle)
extension BackgroundRuntimeMacosPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        lifecycleEventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        lifecycleEventSink = nil
        return nil
    }
}
