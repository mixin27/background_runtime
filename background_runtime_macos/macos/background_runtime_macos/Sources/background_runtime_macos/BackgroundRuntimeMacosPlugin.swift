import Cocoa
import FlutterMacOS
import AVFoundation

public class BackgroundRuntimeMacosPlugin: NSObject, FlutterPlugin {
    private var audioPlayer: AVAudioPlayer?
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.anomalyco.background_runtime/method",
            binaryMessenger: registrar.messenger
        )
        let instance = BackgroundRuntimeMacosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            result(nil)
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

    private func handleStartDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let request = args["request"] as? [String: Any],
              let urlString = request["url"] as? String,
              let url = URL(string: urlString) else {
            result(FlutterError(code: "DOWNLOAD_FAILED", message: "Invalid request", details: nil))
            return
        }

        let taskId = UUID().uuidString
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            if let error = error {
                result(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
                return
            }
            if let location = location,
               let destinationPath = request["destinationPath"] as? String {
                let fileURL = URL(fileURLWithPath: destinationPath)
                try? FileManager.default.moveItem(at: location, to: fileURL)
            }
            result(["taskId": taskId])
        }
        downloadTasks[taskId] = task
        task.resume()
    }

    private func handlePauseDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let taskId = args["taskId"] as? String,
              let task = downloadTasks[taskId] else {
            result(FlutterError(code: "TASK_NOT_FOUND", message: "Download task not found", details: nil))
            return
        }
        task.suspend()
        result(nil)
    }

    private func handleResumeDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let taskId = args["taskId"] as? String,
              let task = downloadTasks[taskId] else {
            result(FlutterError(code: "TASK_NOT_FOUND", message: "Download task not found", details: nil))
            return
        }
        task.resume()
        result(nil)
    }

    private func handleCancelDownload(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let taskId = args["taskId"] as? String,
              let task = downloadTasks[taskId] else {
            result(FlutterError(code: "TASK_NOT_FOUND", message: "Download task not found", details: nil))
            return
        }
        task.cancel()
        downloadTasks.removeValue(forKey: taskId)
        result(nil)
    }

    private func handlePlayAudio(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let track = args["track"] as? [String: Any],
              let sourceString = track["source"] as? String,
              let source = URL(string: sourceString) else {
            result(FlutterError(code: "SERVICE_UNAVAILABLE", message: "Invalid track data", details: nil))
            return
        }

        do {
            let data = try Data(contentsOf: source)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            result(nil)
        } catch {
            result(FlutterError(code: "SERVICE_UNAVAILABLE", message: error.localizedDescription, details: nil))
        }
    }

    private func handlePauseAudio(_ result: @escaping FlutterResult) {
        audioPlayer?.pause()
        result(nil)
    }

    private func handleResumeAudio(_ result: @escaping FlutterResult) {
        audioPlayer?.play()
        result(nil)
    }

    private func handleStopAudio(_ result: @escaping FlutterResult) {
        audioPlayer?.stop()
        audioPlayer = nil
        result(nil)
    }

    private func handleSeekAudio(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let positionMillis = args["positionMillis"] as? Int64 else {
            result(nil)
            return
        }
        audioPlayer?.currentTime = TimeInterval(positionMillis) / 1000.0
        result(nil)
    }

    private func handleShutdown(_ result: @escaping FlutterResult) {
        audioPlayer?.stop()
        audioPlayer = nil
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
        result(nil)
    }
}
