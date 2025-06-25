import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioManager = AudioPlayerManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Playlist Player")
                .font(.title2)
            
            Button(action: {
                audioManager.togglePlayback()
            }) {
                Text(audioManager.isPlaying ? "Pause" : "Play")
                    .font(.headline)
                    .padding()
                    .frame(width: 120)
                    .background(audioManager.isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if audioManager.totalDuration > 0 {
                VStack(spacing: 6) {
                    Slider(
                        value: $audioManager.sliderTime,
                        in: 0...audioManager.totalDuration,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                audioManager.seekToCumulativeTime(audioManager.sliderTime)
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    Text("\(audioManager.formattedCumulativeTime) / \(audioManager.formattedTotalDuration)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
            
            Text("Playlist")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(audioManager.playlist.indices, id: \.self) { index in
                        let filename = audioManager.playlist[index]
                        Button(action: {
                            audioManager.playTrack(at: index)
                        }) {
                            Text(filename)
                                .font(.body)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(audioManager.currentIndex == index ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(audioManager.currentIndex == index ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    @Published var isPlaying = false
    @Published var currentTrackName: String?
    @Published var currentIndex: Int = -1
    
    @Published var playlist: [String] = []
    @Published var trackDurations: [TimeInterval] = []
    @Published var trackStartTimes: [TimeInterval] = []
    @Published var currentTime: TimeInterval = 0
    @Published var sliderTime: TimeInterval = 0
    
    var totalDuration: TimeInterval {
        trackDurations.reduce(0, +)
    }
    
    var cumulativeTime: TimeInterval {
        guard currentIndex >= 0 else { return 0 }
        let previousTime = trackStartTimes[safe: currentIndex] ?? 0
        return previousTime + (audioPlayer?.currentTime ?? 0)
    }
    
    var cumulativeProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return cumulativeTime / totalDuration
    }
    
    var formattedCumulativeTime: String {
        formatTime(cumulativeTime)
    }
    
    var formattedTotalDuration: String {
        formatTime(totalDuration)
    }
    
    override init() {
        super.init()
        playlist = generateFilenames(from: 5)
        loadTrackDurations()
    }
    
    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            stopTimer()
            isPlaying = false
        } else {
            if currentIndex == -1 {
                currentIndex = 0
            }
            playCurrentTrack()
        }
    }
    
    func playTrack(at index: Int) {
        guard index >= 0 && index < playlist.count else { return }
        currentIndex = index
        playCurrentTrack()
    }
    
    private func playCurrentTrack(atTime offset: TimeInterval = 0) {
        guard currentIndex < playlist.count else { return }
        
        let filename = playlist[currentIndex]
        let nameWithoutExtension = filename.replacingOccurrences(of: ".mp3", with: "")
        guard let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "mp3") else {
            print("Audio file \(filename) not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.currentTime = offset
            audioPlayer?.play()
            isPlaying = true
            currentTrackName = filename
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startTimer()
            }
        } catch {
            print("Error playing \(filename): \(error)")
        }
    }
    
    func seekToCumulativeTime(_ time: TimeInterval) {
        guard totalDuration > 0 else { return }
        
        var index = 0
        for (i, start) in trackStartTimes.enumerated() {
            if i + 1 < trackStartTimes.count {
                if time >= start && time < trackStartTimes[i + 1] {
                    index = i
                    break
                }
            } else {
                index = i
            }
        }
        
        let startOffset = trackStartTimes[index]
        let trackOffset = time - startOffset
        
        currentIndex = index
        playCurrentTrack(atTime: trackOffset)
    }
    
    private func loadTrackDurations() {
        var durations: [TimeInterval] = []
        
        for filename in playlist {
            let name = filename.replacingOccurrences(of: ".mp3", with: "")
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
                durations.append(0)
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                durations.append(player.duration)
            } catch {
                print("Error loading duration for \(filename): \(error)")
                durations.append(0)
            }
        }
        
        self.trackDurations = durations
        self.trackStartTimes = durations.enumerated().map { index, _ in
            durations.prefix(index).reduce(0, +)
        }
    }
    
    private func generateFilenames(from count: Int) -> [String] {
        guard count > 0 else { return [] }
        return (1...count).reversed().map { String(format: "%03d.mp3", $0) }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            self.sliderTime = self.cumulativeTime
            self.objectWillChange.send()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopTimer()  // Important to stop before transition
        
        currentIndex += 1
        if currentIndex < playlist.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playCurrentTrack()
            }
        } else {
            isPlaying = false
            currentTrackName = nil
            currentIndex = -1
            sliderTime = totalDuration
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Array safe index helper
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
