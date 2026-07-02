import Foundation
import AVFoundation
import MediaPlayer
import FlutterMacOS

final class AudioManager: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private let persistence: PersistenceManager
    private var playerStateSink: FlutterEventSink?

    private var currentTrackId: String?
    private var currentTitle: String?
    private var currentArtist: String?
    private var currentAlbum: String?
    private var currentSource: String?
    private var currentDurationMillis: Int64?

    init(persistence: PersistenceManager) {
        self.persistence = persistence
        super.init()
        setupRemoteCommandCenter()
    }

    func setPlayerStateSink(_ sink: FlutterEventSink?) {
        playerStateSink = sink
    }

    func playAudio(track: [String: Any], completion: @escaping (FlutterResult)) {
        guard let sourceString = track["source"] as? String,
              let source = URL(string: sourceString) else {
            completion(FlutterError(code: "PLAYBACK_FAILED", message: "Invalid track source", details: nil))
            return
        }

        currentTrackId = track["id"] as? String
        currentTitle = track["title"] as? String
        currentArtist = track["artist"] as? String
        currentAlbum = track["album"] as? String
        currentSource = sourceString
        currentDurationMillis = track["durationMillis"] as? Int64

        do {
            let data = try Data(contentsOf: source)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self

            audioPlayer?.play()

            let positionMillis = Int64(audioPlayer?.currentTime ?? 0) * 1000
            let duration = currentDurationMillis ?? Int64((audioPlayer?.duration ?? 0) * 1000)

            emitPlayerState(
                state: "PLAYING",
                trackId: currentTrackId,
                title: currentTitle,
                artist: currentArtist,
                album: currentAlbum,
                source: sourceString,
                durationMillis: duration,
                positionMillis: positionMillis
            )
            updateNowPlaying(state: "PLAYING", durationMillis: duration, positionMillis: positionMillis)

            let persistedTrack = PersistedAudioTrack(
                trackId: currentTrackId,
                title: currentTitle,
                artist: currentArtist,
                album: currentAlbum,
                source: sourceString,
                durationMillis: duration,
                positionMillis: positionMillis,
                state: "PLAYING"
            )
            persistence.saveAudioTrack(persistedTrack)

            completion(nil)
        } catch {
            completion(FlutterError(code: "PLAYBACK_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    func pauseAudio(completion: @escaping (FlutterResult)) {
        audioPlayer?.pause()
        emitPlayerState(state: "PAUSED")
        updateNowPlaying(state: "PAUSED")
        updatePersistedState(state: "PAUSED")
        completion(nil)
    }

    func resumeAudio(completion: @escaping (FlutterResult)) {
        audioPlayer?.play()
        emitPlayerState(state: "PLAYING")
        updateNowPlaying(state: "PLAYING")
        updatePersistedState(state: "PLAYING")
        completion(nil)
    }

    func stopAudio(completion: @escaping (FlutterResult)) {
        audioPlayer?.stop()
        audioPlayer = nil
        emitPlayerState(state: "STOPPED")
        clearNowPlaying()
        persistence.removeAudioTrack()
        clearTrackMetadata()
        completion(nil)
    }

    func seekAudio(positionMillis: Int64, completion: @escaping (FlutterResult)) {
        audioPlayer?.currentTime = TimeInterval(positionMillis) / 1000.0
        let state = audioPlayer?.isPlaying == true ? "PLAYING" : "PAUSED"
        emitPlayerState(state: state, positionMillis: positionMillis)
        updateNowPlaying(state: state, positionMillis: positionMillis)
        completion(nil)
    }

    func shutdown() {
        audioPlayer?.stop()
        audioPlayer = nil
        clearNowPlaying()
        clearTrackMetadata()
    }

    // MARK: - Private

    private func emitPlayerState(
        state: String,
        trackId: String? = nil,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        source: String? = nil,
        durationMillis: Int64? = nil,
        positionMillis: Int64? = nil
    ) {
        guard let sink = playerStateSink else { return }

        var event: [String: Any] = [
            "state": state,
            "positionMillis": NSNumber(value: positionMillis ?? Int64((audioPlayer?.currentTime ?? 0) * 1000)),
        ]

        if let trackId = trackId ?? currentTrackId { event["trackId"] = trackId }
        if let title = title ?? currentTitle { event["title"] = title }
        if let artist = artist ?? currentArtist { event["artist"] = artist }
        if let album = album ?? currentAlbum { event["album"] = album }
        if let source = source ?? currentSource { event["source"] = source }
        if let durationMillis = durationMillis ?? currentDurationMillis { event["durationMillis"] = NSNumber(value: durationMillis) }

        sink(event)
    }

    private func updatePersistedState(state: String) {
        guard var track = persistence.loadAudioTrack() else { return }
        track.state = state
        track.positionMillis = Int64((audioPlayer?.currentTime ?? 0) * 1000)
        persistence.saveAudioTrack(track)
    }

    private func clearTrackMetadata() {
        currentTrackId = nil
        currentTitle = nil
        currentArtist = nil
        currentAlbum = nil
        currentSource = nil
        currentDurationMillis = nil
    }

    // MARK: - Now Playing

    private func updateNowPlaying(state: String, durationMillis: Int64? = nil, positionMillis: Int64? = nil) {
        let duration = durationMillis ?? currentDurationMillis ?? Int64((audioPlayer?.duration ?? 0) * 1000)
        let position = positionMillis ?? Int64((audioPlayer?.currentTime ?? 0) * 1000)

        var nowPlaying = [String: Any]()

        if let title = currentTitle {
            nowPlaying[MPMediaItemPropertyTitle] = title
        }
        if let artist = currentArtist {
            nowPlaying[MPMediaItemPropertyArtist] = artist
        }
        if let album = currentAlbum {
            nowPlaying[MPMediaItemPropertyAlbumTitle] = album
        }
        nowPlaying[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: Double(duration) / 1000.0)
        nowPlaying[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: Double(position) / 1000.0)
        nowPlaying[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: state == "PLAYING" ? 1.0 : 0.0)

        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
        }
    }

    private func clearNowPlaying() {
        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.audioPlayer?.play()
            self?.emitPlayerState(state: "PLAYING")
            self?.updateNowPlaying(state: "PLAYING")
            self?.updatePersistedState(state: "PLAYING")
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.audioPlayer?.pause()
            self?.emitPlayerState(state: "PAUSED")
            self?.updateNowPlaying(state: "PAUSED")
            self?.updatePersistedState(state: "PAUSED")
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let player = self?.audioPlayer else { return .commandFailed }
            if player.isPlaying {
                player.pause()
                self?.emitPlayerState(state: "PAUSED")
                self?.updateNowPlaying(state: "PAUSED")
                self?.updatePersistedState(state: "PAUSED")
            } else {
                player.play()
                self?.emitPlayerState(state: "PLAYING")
                self?.updateNowPlaying(state: "PLAYING")
                self?.updatePersistedState(state: "PLAYING")
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let positionMillis = Int64(positionEvent.positionTime * 1000)
            self?.audioPlayer?.currentTime = positionEvent.positionTime
            self?.emitPlayerState(state: self?.audioPlayer?.isPlaying == true ? "PLAYING" : "PAUSED", positionMillis: positionMillis)
            self?.updateNowPlaying(state: self?.audioPlayer?.isPlaying == true ? "PLAYING" : "PAUSED", positionMillis: positionMillis)
            return .success
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        emitPlayerState(state: "COMPLETED")
        clearNowPlaying()
        persistence.removeAudioTrack()
        clearTrackMetadata()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        emitPlayerState(state: "ERROR")
        clearNowPlaying()
        if let error = error {
            playerStateSink?(FlutterError(code: "PLAYBACK_FAILED", message: error.localizedDescription, details: nil))
        }
    }
}

// MARK: - FlutterStreamHandler
extension AudioManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        playerStateSink = events

        if let track = persistence.loadAudioTrack() {
            var event: [String: Any] = [
                "state": track.state,
                "positionMillis": NSNumber(value: track.positionMillis),
            ]
            if let id = track.trackId { event["trackId"] = id }
            if let title = track.title { event["title"] = title }
            if let artist = track.artist { event["artist"] = artist }
            if let album = track.album { event["album"] = album }
            if let source = track.source { event["source"] = source }
            if let duration = track.durationMillis { event["durationMillis"] = NSNumber(value: duration) }
            events(event)
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        playerStateSink = nil
        return nil
    }
}
