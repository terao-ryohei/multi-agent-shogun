import Foundation
import AVFoundation

@MainActor
class AudioService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var currentTrack: Int = 0

    private var player: AVAudioPlayer?
    private let tracks = ["shogun", "shogun_reiwa", "shogun_ashigirls"]

    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers, .allowBluetooth])
        try? session.setActive(true)
    }

    func toggle() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            if player == nil {
                loadTrack(currentTrack)
            }
            player?.play()
            isPlaying = true
        }
    }

    func nextTrack() {
        currentTrack = (currentTrack + 1) % tracks.count
        let wasPlaying = isPlaying
        loadTrack(currentTrack)
        if wasPlaying {
            player?.play()
            isPlaying = true
        }
    }

    func duck() {
        player?.volume = 0.05
    }

    func unduck() {
        player?.volume = 1.0
    }

    private func loadTrack(_ index: Int) {
        player?.stop()
        guard let url = Bundle.main.url(forResource: tracks[index], withExtension: "mp3") else {
            return
        }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.numberOfLoops = 0
        player?.prepareToPlay()
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.nextTrack()
            self.player?.play()
            self.isPlaying = true
        }
    }
}
