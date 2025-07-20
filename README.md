# WaveformView

A SwiftUI package for rendering audio waveforms from WAV files. This package provides easy-to-use SwiftUI views that can display audio waveforms in different styles.

## Features

- 📊 **Two Waveform Styles**: Line-based and bar-based waveform visualizations
- 🎨 **Customizable Appearance**: Colors, line width, bar spacing, and more
- ⚡ **Async Processing**: Non-blocking audio file processing
- 🔄 **Format Support**: Handles various audio formats with automatic conversion
- 🛡️ **Error Handling**: Comprehensive error handling with user-friendly messages
- 📱 **SwiftUI Native**: Built specifically for SwiftUI with modern async/await patterns

## Requirements

- iOS 14.0+ / macOS 11.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/WaveformView.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. Go to File → Add Package Dependencies
2. Enter the repository URL
3. Select the version range

## Usage

### Basic Line Waveform

```swift
import SwiftUI
import WaveformView

struct ContentView: View {
    let audioURL = Bundle.main.url(forResource: "sample", withExtension: "wav")!
    
    var body: some View {
        WaveformView(audioURL: audioURL)
            .frame(height: 100)
    }
}
```

### Customized Line Waveform

```swift
WaveformView(
    audioURL: audioURL,
    waveformColor: .blue,
    backgroundColor: .black.opacity(0.1),
    lineWidth: 3.0
)
.frame(height: 150)
```

### Bar-Style Waveform

```swift
WaveformBarView(audioURL: audioURL)
    .frame(height: 100)
```

### Customized Bar Waveform

```swift
WaveformBarView(
    audioURL: audioURL,
    waveformColor: .green,
    backgroundColor: .clear,
    barWidth: 4.0,
    barSpacing: 2.0
)
.frame(height: 200)
```

### Complete Example

```swift
import SwiftUI
import WaveformView

struct AudioVisualizerView: View {
    @State private var selectedStyle = 0
    let audioURL = Bundle.main.url(forResource: "sample", withExtension: "wav")!
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Waveform Visualizer")
                .font(.title)
                .fontWeight(.bold)
            
            Picker("Waveform Style", selection: $selectedStyle) {
                Text("Line").tag(0)
                Text("Bars").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Group {
                if selectedStyle == 0 {
                    WaveformView(
                        audioURL: audioURL,
                        waveformColor: .blue,
                        backgroundColor: .gray.opacity(0.1),
                        lineWidth: 2.5
                    )
                } else {
                    WaveformBarView(
                        audioURL: audioURL,
                        waveformColor: .green,
                        backgroundColor: .gray.opacity(0.1),
                        barWidth: 3.0,
                        barSpacing: 1.5
                    )
                }
            }
            .frame(height: 150)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            Spacer()
        }
    }
}
```

## API Reference

### WaveformView

A SwiftUI view that renders audio waveforms as continuous lines.

#### Initializer

```swift
public init(
    audioURL: URL,
    waveformColor: Color = .blue,
    backgroundColor: Color = .clear,
    lineWidth: CGFloat = 2.0
)
```

**Parameters:**
- `audioURL`: URL to the WAV audio file
- `waveformColor`: Color of the waveform lines (default: blue)
- `backgroundColor`: Background color of the view (default: clear)
- `lineWidth`: Width of the waveform lines (default: 2.0)

### WaveformBarView

A SwiftUI view that renders audio waveforms as vertical bars.

#### Initializer

```swift
public init(
    audioURL: URL,
    waveformColor: Color = .blue,
    backgroundColor: Color = .clear,
    barWidth: CGFloat = 3.0,
    barSpacing: CGFloat = 1.0
)
```

**Parameters:**
- `audioURL`: URL to the WAV audio file
- `waveformColor`: Color of the waveform bars (default: blue)
- `backgroundColor`: Background color of the view (default: clear)
- `barWidth`: Width of each bar (default: 3.0)
- `barSpacing`: Spacing between bars (default: 1.0)

### WaveformProcessor

A utility class for processing audio files and extracting waveform data.

#### Methods

```swift
public static func processAudioFile(url: URL) async throws -> [Float]
```

Processes an audio file and returns normalized amplitude values.

#### Error Types

```swift
public enum WaveformError: Error, LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case processingFailed(String)
    case noAudioData
}
```

## Performance Considerations

- The package automatically downsamples audio files to a maximum of 1000 data points for optimal rendering performance
- Audio processing is performed on a background queue to avoid blocking the main thread
- Large audio files are processed efficiently with streaming techniques

## Supported Audio Formats

- WAV (primary format)
- MP3, M4A, AIFF, and other formats supported by AVAudioFile
- Automatic format conversion for unsupported PCM formats

## Error Handling

The views automatically handle common errors and display user-friendly error messages:

- File not found
- Unsupported audio format
- Audio processing failures
- Empty or corrupted audio files

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Built with SwiftUI and AVFoundation frameworks from Apple.