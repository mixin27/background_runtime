import Foundation
import Flutter

final class DownloadManager: NSObject {
    private var session: URLSession?
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var resumeDataMap: [String: Data] = [:]
    private var pendingCompletions: [String: FlutterResult] = [:]
    private let persistence: PersistenceManager
    private weak var notificationManager: NotificationManager?
    private var downloadEventSink: FlutterEventSink?

    private var backgroundCompletionHandler: (() -> Void)?

    private lazy var backgroundSessionIdentifier: String = {
        return "dev.mixin27.background_runtime.download"
    }()

    init(persistence: PersistenceManager, notificationManager: NotificationManager) {
        self.persistence = persistence
        self.notificationManager = notificationManager
        super.init()
    }

    func setupBackgroundSession() {
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.shouldUseExtendedBackgroundIdleMode = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    func setDownloadEventSink(_ sink: FlutterEventSink?) {
        downloadEventSink = sink
    }

    func setBackgroundCompletionHandler(_ handler: @escaping () -> Void) {
        backgroundCompletionHandler = handler
    }

    func startDownload(request: [String: Any], completion: @escaping (FlutterResult)) {
        guard let urlString = request["url"] as? String,
              let url = URL(string: urlString) else {
            completion(FlutterError(code: "DOWNLOAD_FAILED", message: "Invalid URL", details: nil))
            return
        }

        let taskId = UUID().uuidString
        var urlRequest = URLRequest(url: url)

        if let headersJson = request["headers"] as? String,
           let data = headersJson.data(using: .utf8),
           let headers = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        let task = session?.downloadTask(with: urlRequest)
        activeTasks[taskId] = task
        pendingCompletions[taskId] = completion
        task?.resume()

        let destinationPath = request["destinationPath"] as? String ?? ""
        let saveToPublic = request["saveToPublic"] as? Bool ?? false

        let persisted = PersistedDownload(
            taskId: taskId,
            url: urlString,
            destinationPath: destinationPath,
            headersJson: request["headers"] as? String,
            state: "DOWNLOADING",
            progress: 0,
            totalBytes: 0,
            saveToPublic: saveToPublic,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        persistence.saveDownload(persisted)

        emitDownloadEvent(taskId: taskId, state: "DOWNLOADING", bytesReceived: 0, totalBytes: -1)
    }

    func pauseDownload(taskId: String, completion: @escaping (FlutterResult)) {
        guard let task = activeTasks[taskId] else {
            completion(FlutterError(code: "TASK_NOT_FOUND", message: "Download task not found", details: nil))
            return
        }

        task.cancel { [weak self] resumeData in
            self?.resumeDataMap[taskId] = resumeData
            self?.activeTasks.removeValue(forKey: taskId)
            self?.updateDownloadState(taskId: taskId, state: "PAUSED")
            self?.emitDownloadEvent(taskId: taskId, state: "PAUSED", bytesReceived: -1, totalBytes: -1)
            completion(nil)
        }
    }

    func resumeDownload(taskId: String, completion: @escaping (FlutterResult)) {
        if let resumeData = resumeDataMap.removeValue(forKey: taskId) {
            let task = session?.downloadTask(withResumeData: resumeData)
            activeTasks[taskId] = task
            task?.resume()
            updateDownloadState(taskId: taskId, state: "DOWNLOADING")
            emitDownloadEvent(taskId: taskId, state: "DOWNLOADING", bytesReceived: -1, totalBytes: -1)
            completion(nil)
        } else {
            completion(FlutterError(code: "NO_RESUME_DATA", message: "No resume data available", details: nil))
        }
    }

    func cancelDownload(taskId: String, completion: @escaping (FlutterResult)) {
        activeTasks[taskId]?.cancel()
        activeTasks.removeValue(forKey: taskId)
        resumeDataMap.removeValue(forKey: taskId)
        pendingCompletions.removeValue(forKey: taskId)
        persistence.removeDownload(taskId: taskId)
        emitDownloadEvent(taskId: taskId, state: "CANCELLED", bytesReceived: -1, totalBytes: -1)
        completion(nil)
    }

    func shutdown() {
        let allTaskIds = Array(activeTasks.keys)
        for taskId in allTaskIds {
            activeTasks[taskId]?.cancel()
            activeTasks.removeValue(forKey: taskId)
            resumeDataMap.removeValue(forKey: taskId)
            pendingCompletions.removeValue(forKey: taskId)
        }
    }

    // MARK: - Private

    private func updateDownloadState(taskId: String, state: String) {
        var downloads = persistence.loadAllDownloads()
        if let index = downloads.firstIndex(where: { $0.taskId == taskId }) {
            var updated = downloads[index]
            updated.state = state
            updated.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            downloads[index] = updated
            persistence.saveDownload(updated)
        }
    }

    private func resolvePublicFileName(destinationPath: String, url: String) -> String {
        let basename = (destinationPath as NSString).lastPathComponent
        if basename.isEmpty { return destinationPath }
        if basename.contains(".") { return basename }
        let urlFilename = url
            .split(separator: "/").last?
            .split(separator: "?").first
            .map(String.init) ?? ""
        if urlFilename.contains(".") { return urlFilename }
        return basename
    }

    private func resolvePrivatePath(_ destinationPath: String) -> URL {
        if destinationPath.hasPrefix("/") {
            return URL(fileURLWithPath: destinationPath)
        }
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDir.appendingPathComponent(destinationPath)
    }

    private func emitDownloadEvent(taskId: String, state: String, bytesReceived: Int64, totalBytes: Int64) {
        var event: [String: Any] = [
            "taskId": taskId,
            "state": state,
        ]
        if totalBytes > 0 {
            event["progress"] = Double(bytesReceived) / Double(totalBytes)
            event["bytesReceived"] = NSNumber(value: bytesReceived)
            event["totalBytes"] = NSNumber(value: totalBytes)
        } else if bytesReceived >= 0 {
            event["progress"] = 0.0
            event["bytesReceived"] = NSNumber(value: bytesReceived)
        }
        DispatchQueue.main.async {
            self.downloadEventSink?(event)
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskId = activeTasks.first(where: { $0.value == downloadTask })?.key else {
            return
        }

        let downloads = persistence.loadAllDownloads()
        guard let persisted = downloads.first(where: { $0.taskId == taskId }) else { return }

        let destinationURL: URL

        if persisted.saveToPublic {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = resolvePublicFileName(destinationPath: persisted.destinationPath, url: persisted.url)
            destinationURL = documentsDir.appendingPathComponent(fileName)
        } else {
            destinationURL = resolvePrivatePath(persisted.destinationPath)
        }

        let totalBytesWritten = downloadTask.countOfBytesReceived
        let totalBytesExpected = downloadTask.countOfBytesExpectedToReceive

        do {
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)

            updateDownloadState(taskId: taskId, state: "COMPLETED")
            emitDownloadEvent(taskId: taskId, state: "COMPLETED", bytesReceived: totalBytesWritten, totalBytes: totalBytesExpected)

            let fileName = destinationURL.lastPathComponent
            notificationManager?.postDownloadComplete(taskId: taskId, fileName: fileName)

            if let completion = pendingCompletions.removeValue(forKey: taskId) {
                completion(["taskId": taskId])
            }
        } catch {
            updateDownloadState(taskId: taskId, state: "FAILED")
            emitDownloadEvent(taskId: taskId, state: "FAILED", bytesReceived: totalBytesWritten, totalBytes: totalBytesExpected)

            let fileName = (persisted.destinationPath as NSString).lastPathComponent
            notificationManager?.postDownloadFailed(taskId: taskId, fileName: fileName)

            if let completion = pendingCompletions.removeValue(forKey: taskId) {
                completion(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
            }
        }

        activeTasks.removeValue(forKey: taskId)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskId = activeTasks.first(where: { $0.value == downloadTask })?.key else { return }

        emitDownloadEvent(
            taskId: taskId,
            state: "DOWNLOADING",
            bytesReceived: totalBytesWritten,
            totalBytes: totalBytesExpectedToWrite
        )

        updateDownloadProgress(taskId: taskId, progress: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
    }

    private func updateDownloadProgress(taskId: String, progress: Int64, totalBytes: Int64) {
        var downloads = persistence.loadAllDownloads()
        if let index = downloads.firstIndex(where: { $0.taskId == taskId }) {
            var updated = downloads[index]
            updated.progress = progress
            updated.totalBytes = totalBytes
            updated.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            downloads[index] = updated
            persistence.saveDownload(updated)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskId = activeTasks.first(where: { $0.value == task })?.key else { return }

        if let error = error as NSError? {
            if error.code == NSURLErrorCancelled,
               let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                resumeDataMap[taskId] = resumeData
                return
            }

            let totalBytesWritten = task.countOfBytesReceived
            let totalBytesExpected = task.countOfBytesExpectedToReceive

            updateDownloadState(taskId: taskId, state: "FAILED")
            emitDownloadEvent(taskId: taskId, state: "FAILED", bytesReceived: totalBytesWritten, totalBytes: totalBytesExpected)

            let downloads = persistence.loadAllDownloads()
            if let persisted = downloads.first(where: { $0.taskId == taskId }) {
                let fileName = (persisted.destinationPath as NSString).lastPathComponent
                notificationManager?.postDownloadFailed(taskId: taskId, fileName: fileName)
            }

            if let completion = pendingCompletions.removeValue(forKey: taskId) {
                completion(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
            }
            activeTasks.removeValue(forKey: taskId)
        }
    }
}

// MARK: - URLSessionDelegate
extension DownloadManager: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
        }
    }
}

// MARK: - FlutterStreamHandler
extension DownloadManager: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        downloadEventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        downloadEventSink = nil
        return nil
    }
}
