import SwiftUI
import AVFoundation

/// A SwiftUI view that renders an audio waveform with playback functionality
public struct PlaybackWaveformView: View {
    private let audioURL: URL
    private let waveformColor: Color
    private let progressColor: Color
    private let backgroundColor: Color
    private let lineWidth: CGFloat
    private let showPlayButton: Bool
    
    @StateObject private var audioPlayer: AudioPlayer
    @State private var waveformData: [Float] = []
    @State private var isLoadingWaveform: Bool = true
    @State private var waveformError: String?
    
    /// Initialize a PlaybackWaveformView with audio file URL and customization options
    /// - Parameters:
    ///   - audioURL: URL to the WAV audio file
    ///   - waveformColor: Color of the waveform lines (default: gray)
    ///   - progressColor: Color of the played portion (default: blue)
    ///   - backgroundColor: Background color of the view (default: clear)
    ///   - lineWidth: Width of the waveform lines (default: 2.0)
    ///   - showPlayButton: Whether to show the play/pause button (default: true)
    public init(
        audioURL: URL,
        waveformColor: Color = .gray,
        progressColor: Color = .blue,
        backgroundColor: Color = .clear,
        lineWidth: CGFloat = 2.0,
        showPlayButton: Bool = true
    ) {
        self.audioURL = audioURL
        self.waveformColor = waveformColor
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
        self.lineWidth = lineWidth
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
                        ZStack(alignment: .leading) {
                            // Background waveform
                            PlaybackWaveformShape(data: waveformData)
                                .stroke(waveformColor, lineWidth: lineWidth)
                            
                            // Progress overlay
                            PlaybackWaveformShape(data: waveformData)
                                .stroke(progressColor, lineWidth: lineWidth)
                                .mask(
                                    Rectangle()
                                        .frame(width: geometry.size.width * audioPlayer.progress)
                                        .animation(.linear(duration: 0.1), value: audioPlayer.progress)
                                )
                        }
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

/// A Shape that draws the waveform path for playback views
private struct PlaybackWaveformShape: Shape {
    let data: [Float]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !data.isEmpty else { return path }
        
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        
        let stepX = width / CGFloat(data.count)
        
        for (index, amplitude) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let normalizedAmplitude = CGFloat(amplitude)
            let y = midY - (normalizedAmplitude * midY * 0.8)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}