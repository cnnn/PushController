import Foundation
import AVFoundation
import Combine

/// Audio player that provides playback functionality with progress tracking
@MainActor
public class AudioPlayer: NSObject, ObservableObject {
    
    /// Player state enum
    public enum PlaybackState: Equatable {
        case stopped
        case playing
        case paused
        case loading
        case error(String)
    }
    
    // MARK: - Published Properties
    @Published public var playbackState: PlaybackState = .stopped
    @Published public var currentTime: TimeInterval = 0.0
    @Published public var duration: TimeInterval = 0.0
    @Published public var progress: Double = 0.0 // 0.0 to 1.0
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private let audioURL: URL
    
    // MARK: - Initialization
    public init(audioURL: URL) {
        self.audioURL = audioURL
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopProgressTimer()
        audioPlayer?.stop()
    }
    
    // MARK: - Public Methods
    
    /// Load the audio file and prepare for playback
    public func loadAudio() async {
        playbackState = .loading
        
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.delegate = self
            player.prepareToPlay()
            
            audioPlayer = player
            duration = player.duration
            playbackState = .stopped
        } catch {
            playbackState = .error("Failed to load audio: \(error.localizedDescription)")
        }
    }
    
    /// Start or resume playback
    public func play() {
        guard let player = audioPlayer else {
            Task { await loadAudio() }
            return
        }
        
        if player.play() {
            playbackState = .playing
            startProgressTimer()
        } else {
            playbackState = .error("Failed to start playback")
        }
    }
    
    /// Pause playback
    public func pause() {
        audioPlayer?.pause()
        playbackState = .paused
        stopProgressTimer()
    }
    
    /// Stop playback and reset to beginning
    public func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        progress = 0
        playbackState = .stopped
        stopProgressTimer()
    }
    
    /// Seek to a specific time
    /// - Parameter time: Time in seconds
    public func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
        progress = duration > 0 ? clampedTime / duration : 0
    }
    
    /// Seek to a specific progress (0.0 to 1.0)
    /// - Parameter progress: Progress value between 0.0 and 1.0
    public func seek(to progress: Double) {
        let clampedProgress = max(0.0, min(progress, 1.0))
        let targetTime = duration * clampedProgress
        seek(to: targetTime)
    }
    
    /// Toggle between play and pause
    public func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .stopped:
            play()
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        
        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayer: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                stop()
            } else {
                playbackState = .error("Playback finished with error")
            }
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            let errorMessage = error?.localizedDescription ?? "Unknown decode error"
            playbackState = .error("Decode error: \(errorMessage)")
        }
    }
}