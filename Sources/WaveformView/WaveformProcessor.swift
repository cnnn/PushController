import Foundation
import AVFoundation

/// Processor for extracting waveform data from audio files
public class WaveformProcessor {
    
    /// Errors that can occur during waveform processing
    public enum WaveformError: Error, LocalizedError {
        case fileNotFound
        case unsupportedFormat
        case processingFailed(String)
        case noAudioData
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Audio file not found"
            case .unsupportedFormat:
                return "Unsupported audio format"
            case .processingFailed(let message):
                return "Processing failed: \(message)"
            case .noAudioData:
                return "No audio data found in file"
            }
        }
    }
    
    /// Process an audio file and extract waveform data
    /// - Parameter url: URL of the audio file
    /// - Returns: Array of normalized amplitude values (-1.0 to 1.0)
    public static func processAudioFile(url: URL) async throws -> [Float] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let waveformData = try extractWaveformData(from: url)
                    continuation.resume(returning: waveformData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Extract waveform data from audio file using AVAudioFile
    private static func extractWaveformData(from url: URL) throws -> [Float] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WaveformError.fileNotFound
        }
        
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            throw WaveformError.unsupportedFormat
        }
        
        guard let format = audioFile.processingFormat.commonFormat,
              format == .pcmFormatFloat32 || format == .pcmFormatInt16 || format == .pcmFormatInt32 else {
            // Try to convert to a supported format
            return try extractWaveformDataWithConversion(from: url)
        }
        
        let frameCount = Int(audioFile.length)
        guard frameCount > 0 else {
            throw WaveformError.noAudioData
        }
        
        // Calculate how many samples we want for the waveform (downsample for performance)
        let targetSampleCount = min(frameCount, 1000) // Maximum 1000 points for smooth rendering
        let sampleRate = Int(frameCount / targetSampleCount)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            throw WaveformError.processingFailed("Could not create audio buffer")
        }
        
        do {
            try audioFile.read(into: buffer)
        } catch {
            throw WaveformError.processingFailed("Could not read audio file: \(error.localizedDescription)")
        }
        
        guard let channelData = buffer.floatChannelData?[0] else {
            throw WaveformError.processingFailed("Could not access audio channel data")
        }
        
        var waveformData: [Float] = []
        waveformData.reserveCapacity(targetSampleCount)
        
        // Downsample the audio data
        for i in stride(from: 0, to: frameCount, by: sampleRate) {
            let endIndex = min(i + sampleRate, frameCount)
            var maxAmplitude: Float = 0.0
            
            // Find the maximum amplitude in this sample window
            for j in i..<endIndex {
                let amplitude = abs(channelData[j])
                maxAmplitude = max(maxAmplitude, amplitude)
            }
            
            waveformData.append(maxAmplitude)
        }
        
        return waveformData
    }
    
    /// Extract waveform data with format conversion for unsupported formats
    private static func extractWaveformDataWithConversion(from url: URL) throws -> [Float] {
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            throw WaveformError.unsupportedFormat
        }
        
        // Create a format for conversion (32-bit float, same sample rate and channel count)
        guard let commonFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: audioFile.fileFormat.sampleRate,
            channels: audioFile.fileFormat.channelCount,
            interleaved: false
        ) else {
            throw WaveformError.processingFailed("Could not create conversion format")
        }
        
        let frameCount = Int(audioFile.length)
        guard frameCount > 0 else {
            throw WaveformError.noAudioData
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: commonFormat) else {
            throw WaveformError.processingFailed("Could not create audio converter")
        }
        
        // Create buffers
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(frameCount)),
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: commonFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            throw WaveformError.processingFailed("Could not create conversion buffers")
        }
        
        // Read the entire file
        do {
            try audioFile.read(into: inputBuffer)
        } catch {
            throw WaveformError.processingFailed("Could not read audio file: \(error.localizedDescription)")
        }
        
        // Convert the audio
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            throw WaveformError.processingFailed("Audio conversion failed: \(error.localizedDescription)")
        }
        
        guard let channelData = outputBuffer.floatChannelData?[0] else {
            throw WaveformError.processingFailed("Could not access converted audio data")
        }
        
        // Calculate target sample count and downsample
        let targetSampleCount = min(frameCount, 1000)
        let sampleRate = max(1, frameCount / targetSampleCount)
        
        var waveformData: [Float] = []
        waveformData.reserveCapacity(targetSampleCount)
        
        for i in stride(from: 0, to: frameCount, by: sampleRate) {
            let endIndex = min(i + sampleRate, frameCount)
            var maxAmplitude: Float = 0.0
            
            for j in i..<endIndex {
                let amplitude = abs(channelData[j])
                maxAmplitude = max(maxAmplitude, amplitude)
            }
            
            waveformData.append(maxAmplitude)
        }
        
        return waveformData
    }
}