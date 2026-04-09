import Foundation

enum ChallengeMode: String, CaseIterable, Identifiable, Codable {
    case none = "普通模式"
    case daily = "每日挑战"
    case timed = "限时挑战"
    case noGuess = "无猜挑战"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .none:
            return "标准扫雷模式"
        case .daily:
            return "每天固定一局挑战盘面"
        case .timed:
            return "在时间限制内完成挑战"
        case .noGuess:
            return "尝试生成无需猜测、可用逻辑推进的盘面"
        }
    }
    
    var badgeTitle: String {
        switch self {
        case .none: return "普通"
        case .daily: return "每日"
        case .timed: return "限时"
        case .noGuess: return "无猜"
        }
    }
}
