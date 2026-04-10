import Foundation

struct Achievement: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    var unlockedAt: Date?
    
    var isUnlocked: Bool { unlockedAt != nil }
}

enum AchievementCatalog {
    static let firstWin = Achievement(id: "first_win", title: "首胜", detail: "赢下第一局游戏", icon: "star.fill", unlockedAt: nil)
    static let streak3 = Achievement(id: "streak_3", title: "三连胜", detail: "连续赢下 3 局", icon: "flame.fill", unlockedAt: nil)
    static let noHintWin = Achievement(id: "no_hint_win", title: "无提示通关", detail: "不使用提示赢下一局", icon: "lightbulb.slash.fill", unlockedAt: nil)
    static let strictNoGuess = Achievement(id: "strict_no_guess", title: "严格无猜", detail: "以严格无猜盘面完成通关", icon: "shield.checkered", unlockedAt: nil)
    static let daily7 = Achievement(id: "daily_7", title: "七日打卡", detail: "每日挑战连续完成 7 天", icon: "calendar.badge.checkmark", unlockedAt: nil)
    
    static let all: [Achievement] = [firstWin, streak3, noHintWin, strictNoGuess, daily7]
}
