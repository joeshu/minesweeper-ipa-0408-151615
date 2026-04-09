import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum GameTheme: String, CaseIterable, Identifiable {
    case classic = "经典"
    case modern = "现代"
    case neon = "霓虹"
    case nature = "自然"
    
    var id: String { rawValue }
    
    var cellHiddenColor: Color {
        switch self {
        case .classic:
            return Color(.systemGray5)
        case .modern:
            return Color.blue.opacity(0.15)
        case .neon:
            return Color.purple.opacity(0.3)
        case .nature:
            return Color.green.opacity(0.15)
        }
    }
    
    var cellRevealedColor: Color {
        switch self {
        case .classic:
            return Color(.systemBackground)
        case .modern:
            return Color.blue.opacity(0.05)
        case .neon:
            return Color.black.opacity(0.8)
        case .nature:
            return Color.green.opacity(0.05)
        }
    }
    
    var cellFlaggedColor: Color {
        switch self {
        case .classic:
            return Color.orange.opacity(0.3)
        case .modern:
            return Color.red.opacity(0.2)
        case .neon:
            return Color.pink.opacity(0.4)
        case .nature:
            return Color.orange.opacity(0.25)
        }
    }
    
    var cellExplodedColor: Color {
        switch self {
        case .classic:
            return Color.red.opacity(0.8)
        case .modern:
            return Color.red.opacity(0.9)
        case .neon:
            return Color.red.opacity(1.0)
        case .nature:
            return Color.red.opacity(0.75)
        }
    }
    
    var boardBackgroundColor: Color {
        switch self {
        case .classic:
            return Color(.systemGray6)
        case .modern:
            return Color.blue.opacity(0.08)
        case .neon:
            return Color.purple.opacity(0.15)
        case .nature:
            return Color.green.opacity(0.08)
        }
    }
    
    var gridLineColor: Color {
        switch self {
        case .classic:
            return Color.gray.opacity(0.3)
        case .modern:
            return Color.blue.opacity(0.2)
        case .neon:
            return Color.purple.opacity(0.4)
        case .nature:
            return Color.green.opacity(0.2)
        }
    }
    
    var numberColors: [Color] {
        switch self {
        case .classic:
            return [.blue, .green, .red, .purple, 
                    Color(red: 0.5, green: 0, blue: 0),
                    Color(red: 0, green: 0.5, blue: 0.5),
                    .black, .gray]
        case .modern:
            return [.blue, .green, .orange, .purple,
                    .pink, .cyan, .indigo, .teal]
        case .neon:
            return [.cyan, .green, .yellow, .pink,
                    .orange, .purple, .red, .white]
        case .nature:
            return [.green, .teal, .blue, .indigo,
                    .purple, .orange, .red, .brown]
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var appTheme: AppTheme = .system
    @Published var gameTheme: GameTheme = .modern
    @Published var useGradientBackground: Bool = true
    @Published var enableAnimations: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let appThemeKey = "appTheme"
    private let gameThemeKey = "gameTheme"
    private let useGradientKey = "useGradientBackground"
    private let enableAnimationsKey = "enableAnimations"
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let savedAppTheme = userDefaults.string(forKey: appThemeKey),
           let theme = AppTheme(rawValue: savedAppTheme) {
            appTheme = theme
        }
        
        if let savedGameTheme = userDefaults.string(forKey: gameThemeKey),
           let theme = GameTheme(rawValue: savedGameTheme) {
            gameTheme = theme
        }
        
        useGradientBackground = userDefaults.object(forKey: useGradientKey) as? Bool ?? true
        enableAnimations = userDefaults.object(forKey: enableAnimationsKey) as? Bool ?? true
    }
    
    func setAppTheme(_ theme: AppTheme) {
        appTheme = theme
        userDefaults.set(theme.rawValue, forKey: appThemeKey)
    }
    
    func setGameTheme(_ theme: GameTheme) {
        gameTheme = theme
        userDefaults.set(theme.rawValue, forKey: gameThemeKey)
    }
    
    func setUseGradientBackground(_ value: Bool) {
        useGradientBackground = value
        userDefaults.set(value, forKey: useGradientKey)
    }
    
    func setEnableAnimations(_ value: Bool) {
        enableAnimations = value
        userDefaults.set(value, forKey: enableAnimationsKey)
    }
    
    func colorForNumber(_ number: Int) -> Color {
        guard number >= 1 && number <= 8 else { return .primary }
        return gameTheme.numberColors[number - 1]
    }
}
