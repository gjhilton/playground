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
            
            if let currentTrack = audioManager.currentTrackName {
                Text("Now Playing: \(currentTrack)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentTrackName: String?
    
    private var playlist: [String] = []
    private var currentIndex = 0
    
    override init() {
        super.init()
        playlist = generateFilenames(from: 5)
    }
    
    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            playCurrentTrack()
        }
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
    
    // Automatically play the next track
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentIndex += 1
        if currentIndex < playlist.count {
            playCurrentTrack()
        } else {
            isPlaying = false
            currentTrackName = nil
        }
    }
}

// Full working code ends here
