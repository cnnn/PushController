import SwiftUI
import WaveformView

@main
struct PlaybackWaveformExampleApp: App {
    var body: some Scene {
        WindowGroup {
            PlaybackContentView()
        }
    }
}

struct PlaybackContentView: View {
    @State private var selectedStyle = 0
    @State private var waveformColor = Color.gray
    @State private var progressColor = Color.blue
    @State private var backgroundColor = Color.gray.opacity(0.1)
    @State private var lineWidth: Double = 2.0
    @State private var barWidth: Double = 3.0
    @State private var barSpacing: Double = 1.0
    @State private var showPlayButton = true
    
    // Note: In a real app, you would have an actual audio file URL
    // For this example, we'll use a placeholder URL
    private var audioURL: URL {
        // Replace with your actual audio file URL
        Bundle.main.url(forResource: "sample", withExtension: "wav") ??
        URL(fileURLWithPath: "/path/to/your/audio/file.wav")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Text("Playback Waveform Example")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Interactive audio waveforms with playback controls")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Style Picker
                VStack(alignment: .leading) {
                    Text("Waveform Style")
                        .font(.headline)
                    
                    Picker("Waveform Style", selection: $selectedStyle) {
                        Text("Line").tag(0)
                        Text("Bars").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Playback Waveform Display
                Group {
                    if selectedStyle == 0 {
                        PlaybackWaveformView(
                            audioURL: audioURL,
                            waveformColor: waveformColor,
                            progressColor: progressColor,
                            backgroundColor: backgroundColor,
                            lineWidth: CGFloat(lineWidth),
                            showPlayButton: showPlayButton
                        )
                    } else {
                        PlaybackWaveformBarView(
                            audioURL: audioURL,
                            waveformColor: waveformColor,
                            progressColor: progressColor,
                            backgroundColor: backgroundColor,
                            barWidth: CGFloat(barWidth),
                            barSpacing: CGFloat(barSpacing),
                            showPlayButton: showPlayButton
                        )
                    }
                }
                .frame(height: 180)
                .background(backgroundColor)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "hand.tap")
                                .foregroundColor(.blue)
                            Text("Tap on the waveform to seek")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "hand.draw")
                                .foregroundColor(.blue)
                            Text("Drag on the waveform to scrub")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "play.circle")
                                .foregroundColor(.blue)
                            Text("Use controls to play/pause/stop")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Customization Controls
                ScrollView {
                    VStack(spacing: 15) {
                        Text("Customization")
                            .font(.headline)
                        
                        // Show Play Button Toggle
                        Toggle("Show Play Button", isOn: $showPlayButton)
                            .padding(.horizontal)
                        
                        // Color Pickers
                        VStack(spacing: 10) {
                            HStack {
                                VStack {
                                    Text("Waveform Color")
                                        .font(.caption)
                                    ColorPicker("", selection: $waveformColor)
                                        .labelsHidden()
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("Progress Color")
                                        .font(.caption)
                                    ColorPicker("", selection: $progressColor)
                                        .labelsHidden()
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("Background Color")
                                        .font(.caption)
                                    ColorPicker("", selection: $backgroundColor)
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Style-specific controls
                        if selectedStyle == 0 {
                            // Line style controls
                            VStack {
                                HStack {
                                    Text("Line Width: \(String(format: "%.1f", lineWidth))")
                                    Spacer()
                                }
                                Slider(value: $lineWidth, in: 0.5...5.0, step: 0.1)
                            }
                            .padding(.horizontal)
                        } else {
                            // Bar style controls
                            VStack(spacing: 10) {
                                VStack {
                                    HStack {
                                        Text("Bar Width: \(String(format: "%.1f", barWidth))")
                                        Spacer()
                                    }
                                    Slider(value: $barWidth, in: 1.0...8.0, step: 0.1)
                                }
                                
                                VStack {
                                    HStack {
                                        Text("Bar Spacing: \(String(format: "%.1f", barSpacing))")
                                        Spacer()
                                    }
                                    Slider(value: $barSpacing, in: 0.0...5.0, step: 0.1)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Reset Button
                        Button("Reset to Defaults") {
                            resetToDefaults()
                        }
                        .buttonStyle(.bordered)
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func resetToDefaults() {
        waveformColor = .gray
        progressColor = .blue
        backgroundColor = Color.gray.opacity(0.1)
        lineWidth = 2.0
        barWidth = 3.0
        barSpacing = 1.0
        selectedStyle = 0
        showPlayButton = true
    }
}

struct PlaybackContentView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackContentView()
    }
}