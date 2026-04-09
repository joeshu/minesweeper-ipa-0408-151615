import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    case custom = "自定义"
    
    var id: String { rawValue }
    
    var rows: Int {
        switch self {
        case .easy: return 9
        case .medium: return 16
        case .hard: return 16
        case .custom: return 16
        }
    }
    
    var cols: Int {
        switch self {
        case .easy: return 9
        case .medium: return 16
        case .hard: return 30
        case .custom: return 16
        }
    }
    
    var mineCount: Int {
        switch self {
        case .easy: return 10
        case .medium: return 40
        case .hard: return 99
        case .custom: return 40
        }
    }
    
    var description: String {
        switch self {
        case .easy:
            return "9×9 网格，10 个地雷"
        case .medium:
            return "16×16 网格，40 个地雷"
        case .hard:
            return "16×30 网格，99 个地雷"
        case .custom:
            return "自定义设置"
        }
    }
    
    var highScoreKey: String {
        "highScore_\(self.rawValue)"
    }
}
