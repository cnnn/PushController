import SwiftUI
import AVFoundation

/// A SwiftUI view that renders an audio waveform as vertical bars from a WAV file
public struct WaveformBarView: View {
    private let audioURL: URL
    private let waveformColor: Color
    private let backgroundColor: Color
    private let barWidth: CGFloat
    private let barSpacing: CGFloat
    @State private var waveformData: [Float] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    /// Initialize a WaveformBarView with audio file URL and customization options
    /// - Parameters:
    ///   - audioURL: URL to the WAV audio file
    ///   - waveformColor: Color of the waveform bars (default: blue)
    ///   - backgroundColor: Background color of the view (default: clear)
    ///   - barWidth: Width of each bar (default: 3.0)
    ///   - barSpacing: Spacing between bars (default: 1.0)
    public init(
        audioURL: URL,
        waveformColor: Color = .blue,
        backgroundColor: Color = .clear,
        barWidth: CGFloat = 3.0,
        barSpacing: CGFloat = 1.0
    ) {
        self.audioURL = audioURL
        self.waveformColor = waveformColor
        self.backgroundColor = backgroundColor
        self.barWidth = barWidth
        self.barSpacing = barSpacing
    }
    
    public var body: some View {
        ZStack {
            backgroundColor
            
            if isLoading {
                ProgressView("Loading waveform...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            } else {
                GeometryReader { geometry in
                    HStack(alignment: .center, spacing: barSpacing) {
                        ForEach(Array(waveformData.enumerated()), id: \.offset) { index, amplitude in
                            RoundedRectangle(cornerRadius: barWidth / 2)
                                .fill(waveformColor)
                                .frame(
                                    width: barWidth,
                                    height: max(2, CGFloat(amplitude) * geometry.size.height * 0.9)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            loadWaveformData()
        }
    }
    
    private func loadWaveformData() {
        Task {
            do {
                let data = try await WaveformProcessor.processAudioFile(url: audioURL)
                await MainActor.run {
                    self.waveformData = data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}