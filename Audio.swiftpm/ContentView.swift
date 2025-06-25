import SwiftUI

struct ContentView: View {
    // Example playlist filenames (adjust count/names as needed)
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
