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
}