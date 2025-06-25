// Full working code starts here

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
    @Published var isPlaying = false
    @Published var currentTrackName: String?
    @Published var currentIndex: Int = -1 // -1 means nothing is playing
    
    @Published var playlist: [String] = []
    
    override init() {
        super.init()
        playlist = generateFilenames(from: 5) // Customize the number of tracks here
    }
    
    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
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
    
    private func playCurrentTrack() {
        guard currentIndex < playlist.count else {
            print("Reached end of playlist.")
            return
        }
        
        let filename = playlist[currentIndex]
        let nameWithoutExtension = filename.replacingOccurrences(of: ".mp3", with: "")
        guard let url = Bundle.main.url(forResource: nameWithoutExtension, withExtension: "mp3") else {
            print("Audio file \(filename) not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            currentTrackName = filename
        } catch {
            print("Error playing \(filename): \(error)")
        }
    }
    
    private func generateFilenames(from count: Int) -> [String] {
        guard count > 0 else { return [] }
        return (1...count).reversed().map { String(format: "%03d.mp3", $0) }
    }
    
    // Auto-advance when track finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentIndex += 1
        if currentIndex < playlist.count {
            playCurrentTrack()
        } else {
            isPlaying = false
            currentTrackName = nil
            currentIndex = -1
        }
    }
}

// Full working code ends here
