import SwiftUI
import AVFoundation

/// A SwiftUI view that renders an audio waveform as bars with playback functionality
public struct PlaybackWaveformBarView: View {
    private let audioURL: URL
    private let waveformColor: Color
    private let progressColor: Color
    private let backgroundColor: Color
    private let barWidth: CGFloat
    private let barSpacing: CGFloat
    private let showPlayButton: Bool
    
    @StateObject private var audioPlayer: AudioPlayer
    @State private var waveformData: [Float] = []
    @State private var isLoadingWaveform: Bool = true
    @State private var waveformError: String?
    
    /// Initialize a PlaybackWaveformBarView with audio file URL and customization options
    /// - Parameters:
    ///   - audioURL: URL to the WAV audio file
    ///   - waveformColor: Color of the waveform bars (default: gray)
    ///   - progressColor: Color of the played portion bars (default: blue)
    ///   - backgroundColor: Background color of the view (default: clear)
    ///   - barWidth: Width of each bar (default: 3.0)
    ///   - barSpacing: Spacing between bars (default: 1.0)
    ///   - showPlayButton: Whether to show the play/pause button (default: true)
    public init(
        audioURL: URL,
        waveformColor: Color = .gray,
        progressColor: Color = .blue,
        backgroundColor: Color = .clear,
        barWidth: CGFloat = 3.0,
        barSpacing: CGFloat = 1.0,
        showPlayButton: Bool = true
    ) {
        self.audioURL = audioURL
        self.waveformColor = waveformColor
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.showPlayButton = showPlayButton
        self._audioPlayer = StateObject(wrappedValue: AudioPlayer(audioURL: audioURL))
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Waveform display
            ZStack {
                backgroundColor
                
                if isLoadingWaveform {
                    ProgressView("Loading waveform...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = waveformError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.title2)
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    GeometryReader { geometry in
                        HStack(alignment: .center, spacing: barSpacing) {
                            ForEach(Array(waveformData.enumerated()), id: \.offset) { index, amplitude in
                                let progress = Double(index) / Double(waveformData.count)
                                let isPlayed = progress <= audioPlayer.progress
                                
                                RoundedRectangle(cornerRadius: barWidth / 2)
                                    .fill(isPlayed ? progressColor : waveformColor)
                                    .frame(
                                        width: barWidth,
                                        height: max(2, CGFloat(amplitude) * geometry.size.height * 0.9)
                                    )
                                    .animation(.easeInOut(duration: 0.1), value: isPlayed)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleWaveformTap(location: location, geometry: geometry)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleWaveformDrag(location: value.location, geometry: geometry)
                                }
                        )
                    }
                }
            }
            
            // Playback controls
            if showPlayButton {
                HStack(spacing: 16) {
                    // Play/Pause button
                    Button(action: {
                        audioPlayer.togglePlayPause()
                    }) {
                        Image(systemName: playButtonIcon)
                            .font(.title2)
                            .foregroundColor(progressColor)
                    }
                    .disabled(audioPlayer.playbackState == .loading || audioPlayer.playbackState == .error(""))
                    
                    // Time display
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatTime(audioPlayer.currentTime))
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text(formatTime(audioPlayer.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Stop button
                    Button(action: {
                        audioPlayer.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .disabled(audioPlayer.playbackState == .stopped || audioPlayer.playbackState == .loading)
                }
            }
            
            // Error display for playback issues
            if case .error(let errorMessage) = audioPlayer.playbackState {
                Text("Playback Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            loadWaveformData()
            Task {
                await audioPlayer.loadAudio()
            }
        }
    }
    
    private var playButtonIcon: String {
        switch audioPlayer.playbackState {
        case .playing:
            return "pause.fill"
        case .loading:
            return "hourglass"
        default:
            return "play.fill"
        }
    }
    
    private func loadWaveformData() {
        Task {
            do {
                let data = try await WaveformProcessor.processAudioFile(url: audioURL)
                await MainActor.run {
                    self.waveformData = data
                    self.isLoadingWaveform = false
                }
            } catch {
                await MainActor.run {
                    self.waveformError = error.localizedDescription
                    self.isLoadingWaveform = false
                }
            }
        }
    }
    
    private func handleWaveformTap(location: CGPoint, geometry: GeometryProxy) {
        let progress = location.x / geometry.size.width
        audioPlayer.seek(to: max(0.0, min(progress, 1.0)))
    }
    
    private func handleWaveformDrag(location: CGPoint, geometry: GeometryProxy) {
        let progress = location.x / geometry.size.width
        audioPlayer.seek(to: max(0.0, min(progress, 1.0)))
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}