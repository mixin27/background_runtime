import Foundation

struct PersistedDownload: Codable {
    let taskId: String
    let url: String
    let destinationPath: String
    let headersJson: String?
    var state: String
    var progress: Int64
    var totalBytes: Int64
    let saveToPublic: Bool
    let createdAt: Int64
    var updatedAt: Int64
}

struct PersistedAudioTrack: Codable {
    let trackId: String?
    let title: String?
    let artist: String?
    let album: String?
    let source: String?
    let durationMillis: Int64?
    var positionMillis: Int64
    var state: String
}

struct PersistedConfig: Codable {
    let enableDownloads: Bool
    let enableAudio: Bool
    let enableNotifications: Bool
    let keepAlive: Bool
    let autoResume: Bool
}

final class PersistenceManager {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(suiteName: String = "dev.mixin27.background_runtime.macos") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    func saveDownload(_ download: PersistedDownload) {
        var downloads = loadAllDownloads()
        downloads.removeAll { $0.taskId == download.taskId }
        downloads.append(download)
        if let data = try? encoder.encode(downloads) {
            defaults.set(data, forKey: "downloads")
        }
    }

    func removeDownload(taskId: String) {
        var downloads = loadAllDownloads()
        downloads.removeAll { $0.taskId == taskId }
        if let data = try? encoder.encode(downloads) {
            defaults.set(data, forKey: "downloads")
        }
    }

    func loadAllDownloads() -> [PersistedDownload] {
        guard let data = defaults.data(forKey: "downloads"),
              let downloads = try? decoder.decode([PersistedDownload].self, from: data) else {
            return []
        }
        return downloads
    }

    func loadActiveDownloads() -> [PersistedDownload] {
        loadAllDownloads().filter { $0.state == "DOWNLOADING" || $0.state == "PAUSED" }
    }

    func saveAudioTrack(_ track: PersistedAudioTrack) {
        if let data = try? encoder.encode(track) {
            defaults.set(data, forKey: "audio_track")
        }
    }

    func loadAudioTrack() -> PersistedAudioTrack? {
        guard let data = defaults.data(forKey: "audio_track"),
              let track = try? decoder.decode(PersistedAudioTrack.self, from: data) else {
            return nil
        }
        return track
    }

    func removeAudioTrack() {
        defaults.removeObject(forKey: "audio_track")
    }

    func saveConfig(_ config: PersistedConfig) {
        if let data = try? encoder.encode(config) {
            defaults.set(data, forKey: "runtime_config")
        }
    }

    func loadConfig() -> PersistedConfig? {
        guard let data = defaults.data(forKey: "runtime_config"),
              let config = try? decoder.decode(PersistedConfig.self, from: data) else {
            return nil
        }
        return config
    }
}
