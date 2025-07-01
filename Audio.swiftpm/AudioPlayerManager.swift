import Foundation
import AVFoundation
import Combine
import UIKit

// MARK: - Playback State

enum PlaybackState: Equatable {
    case idle
    case playing
    case paused
    case finished
    case error(String)
}

// MARK: - AudioPlaying Protocol

protocol AudioPlaying: AnyObject {
    var currentTime: TimeInterval { get set }
    var duration: TimeInterval { get }
    
    func prepareToPlay()
    func play()
    func pause()
}

// MARK: - AudioPlayerWrapper

final class AudioPlayerWrapper: NSObject, AudioPlaying {
    private let player: AVAudioPlayer
    
    var currentTime: TimeInterval {
        get { player.currentTime }
        set { player.currentTime = newValue }
    }
    
    var duration: TimeInterval {
        player.duration
    }
    
    init(url: URL) throws {
        self.player = try AVAudioPlayer(contentsOf: url)
        super.init()
    }
    
    func prepareToPlay() {
        player.prepareToPlay()
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func setDelegate(_ delegate: AVAudioPlayerDelegate?) {
        player.delegate = delegate
    }
    
    func asAVAudioPlayer() -> AVAudioPlayer {
        return player
    }
}

// MARK: - Typealias for Factory

typealias AudioPlayerFactory = (_ url: URL) throws -> AudioPlaying

// MARK: - AudioPlayerManager

final class AudioPlayerManager: NSObject, ObservableObject {
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published var sliderTime: TimeInterval = 0
    @Published var currentIndex: Int = -1
    @Published var playlist: [String]
    @Published var lastError: String?
    
    private(set) var trackDurations: [TimeInterval] = []
    private(set) var trackStartTimes: [TimeInterval] = []
    
    private var audioPlayer: AudioPlaying?
    private var displayLink: CADisplayLink?
    private let audioFactory: AudioPlayerFactory
    
    // MARK: - Init
    
    init(playlist: [String], audioFactory: @escaping AudioPlayerFactory = { try AudioPlayerWrapper(url: $0) }) {
        self.playlist = playlist
        self.audioFactory = audioFactory
        super.init()
        preloadDurationsAsync()
    }
    
    var isValidTrackIndex: Bool {
        playlist.indices.contains(currentIndex)
    }
    
    var totalDuration: TimeInterval {
        trackDurations.reduce(0, +)
    }
    
    var cumulativeTime: TimeInterval {
        guard currentIndex >= 0 else { return 0 }
        let offset = trackStartTimes[safe: currentIndex] ?? 0
        return offset + (audioPlayer?.currentTime ?? 0)
    }
    
    var formattedCumulativeTime: String {
        formatTime(cumulativeTime)
    }
    
    var formattedTotalDuration: String {
        formatTime(totalDuration)
    }
    
    // MARK: - Controls
    
    func togglePlayback() {
        guard isValidTrackIndex || playbackState != .playing else { return }
        
        switch playbackState {
        case .playing:
            pause()
        case .paused:
            resume()
        case .idle, .finished, .error:
            if currentIndex == -1 { currentIndex = 0 }
            startPlayback(atTime: 0)
        }
    }
    
    func playTrack(_ index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index
        startPlayback(atTime: 0)
    }
    
    func seekToCumulativeTime(_ time: TimeInterval) {
        guard totalDuration > 0 else { return }
        
        let index = trackStartTimes.lastIndex(where: { $0 <= time }) ?? 0
        let offset = time - trackStartTimes[index]
        
        currentIndex = index
        startPlayback(atTime: offset)
    }
    
    // MARK: - Playback
    
    private func resume() {
        audioPlayer?.play()
        playbackState = .playing
        startDisplayLink()
    }
    
    private func pause() {
        audioPlayer?.pause()
        playbackState = .paused
        stopDisplayLink()
    }
    
    private func startPlayback(atTime offset: TimeInterval) {
        stopDisplayLink()
        
        guard isValidTrackIndex else { return }
        
        let filename = playlist[currentIndex]
        let baseName = filename.replacingOccurrences(of: ".mp3", with: "")
        guard let url = Bundle.main.url(forResource: baseName, withExtension: "mp3") else {
            handleError("Missing audio file: \(filename)")
            return
        }
        
        do {
            let player = try audioFactory(url)
            
            if let wrapper = player as? AudioPlayerWrapper {
                wrapper.setDelegate(self)
            }
            
            player.prepareToPlay()
            player.currentTime = offset
            self.audioPlayer = player
            player.play()
            playbackState = .playing
            startDisplayLink()
        } catch {
            handleError("Playback failed: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ message: String) {
        lastError = message
        playbackState = .error(message)
    }
    
    // MARK: - Duration Preload
    
    private func preloadDurationsAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            let durations = self.playlist.map { filename -> TimeInterval in
                let name = filename.replacingOccurrences(of: ".mp3", with: "")
                guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
                      let player = try? AVAudioPlayer(contentsOf: url) else {
                    return 0
                }
                return player.duration
            }
            
            let startTimes = durations.enumerated().map { index, _ in
                durations.prefix(index).reduce(0, +)
            }
            
            DispatchQueue.main.async {
                self.trackDurations = durations
                self.trackStartTimes = startTimes
            }
        }
    }
    
    // MARK: - DisplayLink for UI Sync
    
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateProgress() {
        sliderTime = cumulativeTime
        objectWillChange.send()
    }
    
    // MARK: - Time Format
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopDisplayLink()
        currentIndex += 1
        if currentIndex < playlist.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startPlayback(atTime: 0)
            }
        } else {
            playbackState = .finished
            currentIndex = -1
            sliderTime = totalDuration
        }
    }
}

// MARK: - Safe Array Access Helper

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
