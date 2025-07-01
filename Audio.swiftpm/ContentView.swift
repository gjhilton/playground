import SwiftUI

struct ContentView: View {
    private static let filenames = (1...5).reversed().map { String(format: "%03d.mp3", $0) }
    
    @StateObject private var audioManager = AudioPlayerManager(playlist: filenames)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Playlist Player")
                .font(.title2)
            
            // Error Handling
            if case .error(let message) = audioManager.playbackState {
                Text("⚠️ \(message)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Playback Controls
            PlaybackControlsView(
                isPlaying: audioManager.playbackState == .playing,
                onToggle: audioManager.togglePlayback
            )
            
            // Progress Slider
            if audioManager.totalDuration > 0 {
                ProgressViewBar(
                    sliderTime: $audioManager.sliderTime,
                    totalDuration: audioManager.totalDuration,
                    formattedTime: audioManager.formattedCumulativeTime,
                    formattedTotal: audioManager.formattedTotalDuration,
                    isEnabled: audioManager.playbackState == .playing,
                    onSeek: audioManager.seekToCumulativeTime
                )
            }
            
            // Track Counter
            if audioManager.isValidTrackIndex {
                Text("Track \(audioManager.currentIndex + 1) of \(audioManager.playlist.count)")
                    .font(.subheadline)
            }
            
            // Playlist View
            PlaylistView(
                playlist: audioManager.playlist,
                currentIndex: audioManager.currentIndex,
                onTrackTap: audioManager.playTrack
            )
        }
        .padding()
    }
}
