import SwiftUI

// MARK: - PlaylistView

struct PlaylistView: View {
    let playlist: [String]
    let currentIndex: Int
    let onTrackTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Playlist")
                .font(.headline)
                .padding(.leading)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(playlist.indices, id: \.self) { index in
                            let filename = playlist[index]
                            Button(action: {
                                onTrackTap(index)
                            }) {
                                Text(filename)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
