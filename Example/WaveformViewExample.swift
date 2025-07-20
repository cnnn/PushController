import SwiftUI
import WaveformView

@main
struct WaveformViewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedStyle = 0
    @State private var waveformColor = Color.blue
    @State private var backgroundColor = Color.gray.opacity(0.1)
    @State private var lineWidth: Double = 2.0
    @State private var barWidth: Double = 3.0
    @State private var barSpacing: Double = 1.0
    
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
                    Text("WaveformView Example")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Visualize audio waveforms in SwiftUI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                
                // Waveform Display
                Group {
                    if selectedStyle == 0 {
                        WaveformView(
                            audioURL: audioURL,
                            waveformColor: waveformColor,
                            backgroundColor: backgroundColor,
                            lineWidth: CGFloat(lineWidth)
                        )
                    } else {
                        WaveformBarView(
                            audioURL: audioURL,
                            waveformColor: waveformColor,
                            backgroundColor: backgroundColor,
                            barWidth: CGFloat(barWidth),
                            barSpacing: CGFloat(barSpacing)
                        )
                    }
                }
                .frame(height: 150)
                .background(backgroundColor)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Customization Controls
                ScrollView {
                    VStack(spacing: 15) {
                        Text("Customization")
                            .font(.headline)
                        
                        // Color Pickers
                        HStack {
                            VStack {
                                Text("Waveform Color")
                                    .font(.caption)
                                ColorPicker("", selection: $waveformColor)
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
        waveformColor = .blue
        backgroundColor = Color.gray.opacity(0.1)
        lineWidth = 2.0
        barWidth = 3.0
        barSpacing = 1.0
        selectedStyle = 0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}