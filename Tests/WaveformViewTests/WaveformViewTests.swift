import XCTest
@testable import WaveformView

final class WaveformViewTests: XCTestCase {
    
    func testWaveformProcessorErrorTypes() {
        // Test that error types are properly defined
        let fileNotFoundError = WaveformProcessor.WaveformError.fileNotFound
        let unsupportedFormatError = WaveformProcessor.WaveformError.unsupportedFormat
        let processingFailedError = WaveformProcessor.WaveformError.processingFailed("test")
        let noAudioDataError = WaveformProcessor.WaveformError.noAudioData
        
        XCTAssertEqual(fileNotFoundError.errorDescription, "Audio file not found")
        XCTAssertEqual(unsupportedFormatError.errorDescription, "Unsupported audio format")
        XCTAssertEqual(processingFailedError.errorDescription, "Processing failed: test")
        XCTAssertEqual(noAudioDataError.errorDescription, "No audio data found in file")
    }
    
    func testWaveformProcessorWithInvalidFile() async {
        // Test with a non-existent file
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.wav")
        
        do {
            let _ = try await WaveformProcessor.processAudioFile(url: invalidURL)
            XCTFail("Expected an error to be thrown")
        } catch let error as WaveformProcessor.WaveformError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("Expected WaveformError.fileNotFound, got \(error)")
        }
    }
    
    func testWaveformViewInitialization() {
        // Test that WaveformView can be initialized with default parameters
        let testURL = URL(fileURLWithPath: "/test/audio.wav")
        let waveformView = WaveformView(audioURL: testURL)
        
        // This test mainly ensures the initializer compiles correctly
        XCTAssertNotNil(waveformView)
    }
    
    func testWaveformBarViewInitialization() {
        // Test that WaveformBarView can be initialized with custom parameters
        let testURL = URL(fileURLWithPath: "/test/audio.wav")
        let waveformBarView = WaveformBarView(
            audioURL: testURL,
            waveformColor: .red,
            backgroundColor: .black,
            barWidth: 5.0,
            barSpacing: 2.0
        )
        
        // This test mainly ensures the initializer compiles correctly
        XCTAssertNotNil(waveformBarView)
    }
    
    func testPlaybackWaveformViewInitialization() {
        // Test that PlaybackWaveformView can be initialized with default parameters
        let testURL = URL(fileURLWithPath: "/test/audio.wav")
        let playbackWaveformView = PlaybackWaveformView(audioURL: testURL)
        
        // This test mainly ensures the initializer compiles correctly
        XCTAssertNotNil(playbackWaveformView)
    }
    
    func testPlaybackWaveformBarViewInitialization() {
        // Test that PlaybackWaveformBarView can be initialized with custom parameters
        let testURL = URL(fileURLWithPath: "/test/audio.wav")
        let playbackWaveformBarView = PlaybackWaveformBarView(
            audioURL: testURL,
            waveformColor: .green,
            progressColor: .orange,
            backgroundColor: .black,
            barWidth: 4.0,
            barSpacing: 1.5,
            showPlayButton: false
        )
        
        // This test mainly ensures the initializer compiles correctly
        XCTAssertNotNil(playbackWaveformBarView)
    }
    
    func testAudioPlayerInitialization() {
        // Test that AudioPlayer can be initialized
        let testURL = URL(fileURLWithPath: "/test/audio.wav")
        let audioPlayer = AudioPlayer(audioURL: testURL)
        
        XCTAssertNotNil(audioPlayer)
        XCTAssertEqual(audioPlayer.playbackState, .stopped)
        XCTAssertEqual(audioPlayer.currentTime, 0.0)
        XCTAssertEqual(audioPlayer.duration, 0.0)
        XCTAssertEqual(audioPlayer.progress, 0.0)
    }
    
    func testPlaybackStateEquality() {
        // Test that playback states can be compared
        let state1 = AudioPlayer.PlaybackState.stopped
        let state2 = AudioPlayer.PlaybackState.stopped
        let state3 = AudioPlayer.PlaybackState.playing
        
        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
    }
}