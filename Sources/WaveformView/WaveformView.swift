import SwiftUI
import AVFoundation

/// A SwiftUI view that renders an audio waveform from a WAV file
public struct WaveformView: View {
    private let audioURL: URL
    private let waveformColor: Color
    private let backgroundColor: Color
    private let lineWidth: CGFloat
    @State private var waveformData: [Float] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    /// Initialize a WaveformView with audio file URL and customization options
    /// - Parameters:
    ///   - audioURL: URL to the WAV audio file
    ///   - waveformColor: Color of the waveform lines (default: blue)
    ///   - backgroundColor: Background color of the view (default: clear)
    ///   - lineWidth: Width of the waveform lines (default: 2.0)
    public init(
        audioURL: URL,
        waveformColor: Color = .blue,
        backgroundColor: Color = .clear,
        lineWidth: CGFloat = 2.0
    ) {
        self.audioURL = audioURL
        self.waveformColor = waveformColor
        self.backgroundColor = backgroundColor
        self.lineWidth = lineWidth
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
                WaveformShape(data: waveformData)
                    .stroke(waveformColor, lineWidth: lineWidth)
                    .background(backgroundColor)
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

/// A Shape that draws the waveform path
private struct WaveformShape: Shape {
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
            let y = midY - (normalizedAmplitude * midY * 0.8) // Scale to 80% of available height
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}