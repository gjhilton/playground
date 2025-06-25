import Foundation
import AVFoundation
import Combine

final class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    @Published var sliderTime: TimeInterval = 0
    @Published var currentIndex: Int = -1
    @Published var playlist: [String]
    
    private(set) var trackDurations: [TimeInterval] = []
    private(set) var trackStartTimes: [TimeInterval] = []
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
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
    
    init(playlist: [String]) {
        self.playlist = playlist
        super.init()
        preloadDurations()
    }
    
    // MARK: - Public Controls
    
    func togglePlayback() {
        guard isValidTrackIndex || !isPlaying else { return }
        
        if isPlaying {
            pause()
        } else {
            if currentIndex == -1 { currentIndex = 0 }
            resumeOrPlay()
        }
    }
    
    func playTrack(at index: Int) {
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
    
    // MARK: - Internal Logic
    
    private func preloadDurations() {
        trackDurations = playlist.map { filename in
            let name = filename.replacingOccurrences(of: ".mp3", with: "")
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
                  let player = try? AVAudioPlayer(contentsOf: url)
            else {
                return 0
            }
            return player.duration
        }
        
        trackStartTimes = trackDurations.enumerated().map { index, _ in
            trackDurations.prefix(index).reduce(0, +)
        }
    }
    
    private func resumeOrPlay() {
        if let player = audioPlayer {
            player.play()
            isPlaying = true
            startTimer()
        } else {
            startPlayback(atTime: 0)
        }
    }
    
    private func pause() {
        audioPlayer?.pause()
        stopTimer()
        isPlaying = false
    }
    
    private func startPlayback(atTime offset: TimeInterval) {
        stopTimer()
        
        guard isValidTrackIndex else { return }
        
        let filename = playlist[currentIndex]
        let baseName = filename.replacingOccurrences(of: ".mp3", with: "")
        guard let url = Bundle.main.url(forResource: baseName, withExtension: "mp3") else {
            print("⚠️ Missing audio: \(filename)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.currentTime = offset
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        } catch {
            print("❌ Playback error: \(error)")
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let player = self.audioPlayer else { return }
            self.sliderTime = self.cumulativeTime
            self.objectWillChange.send()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopTimer()
        currentIndex += 1
        if currentIndex < playlist.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startPlayback(atTime: 0)
            }
        } else {
            isPlaying = false
            currentIndex = -1
            sliderTime = totalDuration
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
