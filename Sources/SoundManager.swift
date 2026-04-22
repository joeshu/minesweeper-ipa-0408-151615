import AVFoundation
import Foundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isSoundEnabled: Bool = true
    @Published var volume: Float = 0.5
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let userDefaults = UserDefaults.standard
    private let soundEnabledKey = "soundEnabled"
    private let volumeKey = "soundVolume"
    
    private init() {
        loadSettings()
        preloadSounds()
    }
    
    private func loadSettings() {
        isSoundEnabled = userDefaults.bool(forKey: soundEnabledKey)
        volume = userDefaults.float(forKey: volumeKey)
        if volume == 0 {
            volume = 0.5
        }
    }
    
    private func preloadSounds() {
        let sounds = ["click", "flag", "win", "lose"]
        for sound in sounds {
            if let url = Bundle.main.url(forResource: sound, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[sound] = player
                } catch {
                    print("Failed to load sound: \(sound)")
                }
            }
        }
    }
    
    func playSound(_ name: String) {
        guard isSoundEnabled else { return }
        
        if let player = audioPlayers[name] {
            player.volume = volume
            player.currentTime = 0
            player.play()
        }
    }
    
    func playClick(isRapid: Bool = false) {
        if isRapid {
            playSound("flag")
        } else {
            playSound("click")
        }
    }
    
    func playFlag(isRapid: Bool = false) {
        if isRapid {
            playSound("click")
        } else {
            playSound("flag")
        }
    }
    
    func playWin() {
        playSound("win")
    }
    
    func playLose() {
        playSound("lose")
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
        userDefaults.set(isSoundEnabled, forKey: soundEnabledKey)
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        userDefaults.set(volume, forKey: volumeKey)
    }
}
