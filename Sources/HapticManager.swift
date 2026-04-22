import UIKit
import Foundation

class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    @Published var isHapticEnabled: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let hapticEnabledKey = "hapticEnabled"
    
    // 不同强度的触觉反馈生成器
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        loadSettings()
        prepareHaptics()
    }
    
    private func loadSettings() {
        isHapticEnabled = userDefaults.object(forKey: hapticEnabledKey) as? Bool ?? true
    }
    
    private func prepareHaptics() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticEnabled else { return }
        
        switch style {
        case .light:
            lightImpact.impactOccurred()
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        case .soft:
            softImpact.impactOccurred()
        case .rigid:
            rigidImpact.impactOccurred()
        @unknown default:
            mediumImpact.impactOccurred()
        }
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticEnabled else { return }
        notification.notificationOccurred(type)
    }
    
    func selectionChanged() {
        guard isHapticEnabled else { return }
        selection.selectionChanged()
    }
    
    // MARK: - 游戏特定的触觉反馈
    
    func cellTapped(isRapid: Bool = false) {
        impact(isRapid ? .soft : .light)
    }
    
    func cellFlagged(isRapid: Bool = false) {
        impact(isRapid ? .rigid : .medium)
    }
    
    func cellQuestioned() {
        impact(.soft)
    }
    
    func gameWon() {
        // 胜利时连续震动
        notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.light)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impact(.medium)
        }
    }
    
    func gameLost() {
        notification(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.heavy)
        }
    }
    
    func mineExploded() {
        impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impact(.rigid)
        }
    }
    
    func undo() {
        impact(.soft)
    }
    
    func pause() {
        impact(.medium)
    }
    
    func resume() {
        impact(.light)
    }
    
    func hint() {
        selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.selectionChanged()
        }
    }
    
    func newGame() {
        impact(.medium)
    }
    
    func toggleHaptic() {
        isHapticEnabled.toggle()
        userDefaults.set(isHapticEnabled, forKey: hapticEnabledKey)
    }
}
