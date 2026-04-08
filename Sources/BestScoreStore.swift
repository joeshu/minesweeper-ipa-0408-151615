// Last updated: 2026-04-08 18:18 CST
import Foundation

struct BestScoreStore {
    private static let keyPrefix = "minesweeper.best."

    static func bestTime(for difficulty: Difficulty) -> Int? {
        let value = UserDefaults.standard.integer(forKey: keyPrefix + difficulty.rawValue)
        return value > 0 ? value : nil
    }

    static func registerWin(seconds: Int, difficulty: Difficulty) {
        guard seconds > 0 else { return }
        let key = keyPrefix + difficulty.rawValue
        let current = UserDefaults.standard.integer(forKey: key)
        if current == 0 || seconds < current {
            UserDefaults.standard.set(seconds, forKey: key)
        }
    }
}
