import SwiftUI
import AVFoundation

// MARK: - ContentView

struct ContentView: View {
    private static let filenames = (1...5).reversed().map { String(format: "%03d.mp3", $0) }
    @StateObject private var audioManager = AudioPlayerManager(playlist: filenames)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Playlist Player")
                .font(.title2)
            
            PlaybackControlsView(isPlaying: audioManager.isPlaying) {
                audioManager.togglePlayback()
            }
            
            if audioManager.totalDuration > 0 {
                ProgressViewBar(
                    sliderTime: $audioManager.sliderTime,
                    totalDuration: audioManager.totalDuration,
                    formattedTime: audioManager.formattedCumulativeTime,
                    formattedTotal: audioManager.formattedTotalDuration,
                    isEnabled: audioManager.isPlaying,
                    onSeek: audioManager.seekToCumulativeTime
                )
            }
            
            if audioManager.isValidTrackIndex {
                Text("Track \(audioManager.currentIndex + 1) of \(audioManager.playlist.count)")
                    .font(.subheadline)
                    .padding(.top, 8)
            }
            
            PlaylistView(
                playlist: audioManager.playlist,
                currentIndex: audioManager.currentIndex,
                onTrackTap: audioManager.playTrack
            )
        }
        .padding()
    }
}

// MARK: - PlaybackControlsView

struct PlaybackControlsView: View {
    let isPlaying: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(isPlaying ? "Pause" : "Play")
                .font(.headline)
                .padding()
                .frame(width: 120)
                .background(isPlaying ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

// MARK: - ProgressViewBar

struct ProgressViewBar: View {
    @Binding var sliderTime: TimeInterval
    let totalDuration: TimeInterval
    let formattedTime: String
    let formattedTotal: String
    let isEnabled: Bool
    let onSeek: (TimeInterval) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Slider(
                value: $sliderTime,
                in: 0...totalDuration,
                onEditingChanged: { editing in
                    if !editing { onSeek(sliderTime) }
                }
            )
            .disabled(!isEnabled)
            .padding(.horizontal)
            
            Text("\(formattedTime) / \(formattedTotal)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

// MARK: - PlaylistView

struct PlaylistView: View {
    let playlist: [String]
    let currentIndex: Int
    let onTrackTap: (Int) -> Void
    
    var body: some View {
        Text("Playlist")
            .font(.headline)
            .padding(.top)
        
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(playlist.indices, id: \.self) { index in
                        let filename = playlist[index]
                        Button(action: {
                            onTrackTap(index)
                        }) {
                            Text(filename)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(currentIndex == index ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(currentIndex == index ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { index in
                withAnimation {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
        }
    }
}

// MARK: - AudioPlayerManager

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
