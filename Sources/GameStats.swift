import Foundation

struct DailyChallengeStatus: Codable {
    let dateKey: String
    let bestTime: TimeInterval
    let completed: Bool
}

struct HintDescriptor {
    enum Kind {
        case safe
        case flag
        case risky
        case none
    }
    
    let position: (row: Int, col: Int)?
    let message: String
    let kind: Kind
}

struct GameRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let difficulty: String
    let challengeMode: String?
    let generationQuality: String?
    let result: GameResult
    let duration: TimeInterval
    let rows: Int
    let cols: Int
    let mineCount: Int
    
    enum GameResult: String, Codable {
        case won = "胜利"
        case lost = "失败"
    }
}

class GameStats: ObservableObject {
    @Published var records: [GameRecord] = []
    @Published var totalGames: Int = 0
    @Published var wins: Int = 0
    @Published var losses: Int = 0
    @Published var bestTimes: [String: TimeInterval] = [:]
    @Published var dailyChallengeStatuses: [String: DailyChallengeStatus] = [:]
    @Published var noGuessWins: Int = 0
    @Published var noGuessGames: Int = 0
    @Published var noGuessBestTime: TimeInterval? = nil
    @Published var noGuessStrictBoards: Int = 0
    @Published var noGuessFallbackBoards: Int = 0
    @Published var achievements: [Achievement] = AchievementCatalog.all
    
    private let recordsKey = "gameRecords"
    private let dailyChallengeStatusKey = "dailyChallengeStatuses"
    private let achievementsKey = "achievements"
    private let maxRecords = 100
    
    init() {
        loadRecords()
    }
    
    func addRecord(difficulty: Difficulty, challengeMode: ChallengeMode = .none, generationQuality: String? = nil, hasUsedHint: Bool = false, result: GameRecord.GameResult, duration: TimeInterval, rows: Int, cols: Int, mineCount: Int) -> [Achievement] {
        let record = GameRecord(
            id: UUID(),
            date: Date(),
            difficulty: difficulty.rawValue,
            challengeMode: challengeMode == .none ? nil : challengeMode.rawValue,
            generationQuality: generationQuality,
            result: result,
            duration: duration,
            rows: rows,
            cols: cols,
            mineCount: mineCount
        )
        
        records.insert(record, at: 0)
        
        // 限制记录数量
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        
        // 更新最佳时间
        if result == .won {
            let key = difficulty.rawValue
            if let currentBest = bestTimes[key] {
                if duration < currentBest {
                    bestTimes[key] = duration
                }
            } else {
                bestTimes[key] = duration
            }
            
            if challengeMode == .daily {
                let dateKey = currentDateKey()
                let current = dailyChallengeStatuses[dateKey]
                if current == nil || duration < current!.bestTime {
                    dailyChallengeStatuses[dateKey] = DailyChallengeStatus(dateKey: dateKey, bestTime: duration, completed: true)
                }
            }
            
            if challengeMode == .noGuess {
                if let currentBest = noGuessBestTime {
                    if duration < currentBest {
                        noGuessBestTime = duration
                    }
                } else {
                    noGuessBestTime = duration
                }
            }
        }
        
        updateStats()
        let unlocked = evaluateAchievements(for: record, hasUsedHint: hasUsedHint)
        saveRecords()
        return unlocked
    }
    

    private func evaluateAchievements(for record: GameRecord, hasUsedHint: Bool) -> [Achievement] {
        var unlocked: [Achievement] = []
        if record.result == .won, let a = unlockAchievement(id: "first_win") { unlocked.append(a) }
        if consecutiveWinsCount() >= 3, let a = unlockAchievement(id: "streak_3") { unlocked.append(a) }
        if consecutiveWinsCount() >= 5, let a = unlockAchievement(id: "streak_5") { unlocked.append(a) }
        if consecutiveWinsCount() >= 10, let a = unlockAchievement(id: "streak_10") { unlocked.append(a) }
        if record.result == .won && !hasUsedHint, let a = unlockAchievement(id: "no_hint_win") { unlocked.append(a) }
        if record.result == .won && record.challengeMode == ChallengeMode.noGuess.rawValue && (record.generationQuality ?? "").contains("严格"), let a = unlockAchievement(id: "strict_no_guess") { unlocked.append(a) }
        if record.result == .won && getDailyChallengeStreak() >= 7, let a = unlockAchievement(id: "daily_7") { unlocked.append(a) }
        return unlocked
    }
    
    func newlyUnlockedAchievements(for record: GameRecord, hasUsedHint: Bool) -> [Achievement] {
        var unlocked: [Achievement] = []
        
        if record.result == .won, let a = unlockAchievement(id: "first_win") { unlocked.append(a) }
        if consecutiveWinsCount() >= 3, let a = unlockAchievement(id: "streak_3") { unlocked.append(a) }
        if consecutiveWinsCount() >= 5, let a = unlockAchievement(id: "streak_5") { unlocked.append(a) }
        if consecutiveWinsCount() >= 10, let a = unlockAchievement(id: "streak_10") { unlocked.append(a) }
        if record.result == .won && !hasUsedHint, let a = unlockAchievement(id: "no_hint_win") { unlocked.append(a) }
        if record.result == .won && record.challengeMode == ChallengeMode.noGuess.rawValue && (record.generationQuality ?? "").contains("严格"), let a = unlockAchievement(id: "strict_no_guess") { unlocked.append(a) }
        if record.result == .won && getDailyChallengeStreak() >= 7, let a = unlockAchievement(id: "daily_7") { unlocked.append(a) }
        
        return unlocked
    }
    
    private func consecutiveWinsCount() -> Int {
        var count = 0
        for record in records {
            if record.result == .won {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    func unlockAchievement(id: String) -> Achievement? {
        guard let idx = achievements.firstIndex(where: { $0.id == id }), achievements[idx].unlockedAt == nil else { return nil }
        achievements[idx].unlockedAt = Date()
        return achievements[idx]
    }

    private func updateStats() {
        totalGames = records.count
        wins = records.filter { $0.result == .won }.count
        losses = records.filter { $0.result == .lost }.count
        
        let noGuessRecords = records.filter { $0.challengeMode == ChallengeMode.noGuess.rawValue }
        noGuessGames = noGuessRecords.count
        noGuessWins = noGuessRecords.filter { $0.result == .won }.count
        noGuessStrictBoards = noGuessRecords.filter { ($0.generationQuality ?? "").contains("严格") }.count
        noGuessFallbackBoards = noGuessRecords.filter { ($0.generationQuality ?? "").contains("回退") || ($0.generationQuality ?? "").contains("未命中") }.count
    }
    
    func getWinRate(for difficulty: Difficulty? = nil) -> Double {
        let filteredRecords = difficulty != nil ? records.filter { $0.difficulty == difficulty!.rawValue } : records
        let total = filteredRecords.count
        let winCount = filteredRecords.filter { $0.result == .won }.count
        return total > 0 ? Double(winCount) / Double(total) * 100 : 0
    }
    
    func getBestTime(for difficulty: Difficulty) -> TimeInterval? {
        return bestTimes[difficulty.rawValue]
    }
    
    func getRecords(for difficulty: Difficulty? = nil) -> [GameRecord] {
        if let difficulty = difficulty {
            return records.filter { $0.difficulty == difficulty.rawValue }
        }
        return records
    }
    
    func getAverageTime(for difficulty: Difficulty) -> TimeInterval? {
        let wonGames = records.filter { $0.difficulty == difficulty.rawValue && $0.result == .won }
        guard !wonGames.isEmpty else { return nil }
        let totalTime = wonGames.reduce(0) { $0 + $1.duration }
        return totalTime / Double(wonGames.count)
    }
    
    func getChallengeRecords() -> [GameRecord] {
        records.filter { $0.challengeMode != nil }
    }
    
    func getChallengeWinRate() -> Double {
        let challengeRecords = getChallengeRecords()
        guard !challengeRecords.isEmpty else { return 0 }
        let wins = challengeRecords.filter { $0.result == .won }.count
        return Double(wins) / Double(challengeRecords.count) * 100
    }
    
    func getTodayDailyChallengeStatus() -> DailyChallengeStatus? {
        dailyChallengeStatuses[currentDateKey()]
    }
    
    func getDailyChallengeStreak() -> Int {
        var streak = 0
        let calendar = Calendar(identifier: .gregorian)
        var day = Date()
        
        while true {
            let key = dateKey(for: day)
            guard dailyChallengeStatuses[key]?.completed == true else { break }
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }
    
    func getDailyChallengeCompletedDays() -> Int {
        dailyChallengeStatuses.values.filter { $0.completed }.count
    }
    
    func getNoGuessWinRate() -> Double {
        guard noGuessGames > 0 else { return 0 }
        return Double(noGuessWins) / Double(noGuessGames) * 100
    }
    
    func unlockedAchievementsCount() -> Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    func bestWinStreak() -> Int {
        var best = 0
        var current = 0
        for record in records.reversed() {
            if record.result == .won {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
    
    private func currentDateKey() -> String {
        dateKey(for: Date())
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
    
    func clearAllRecords() {
        records.removeAll()
        bestTimes.removeAll()
        updateStats()
        saveRecords()
    }
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
        if let encoded = try? JSONEncoder().encode(bestTimes) {
            UserDefaults.standard.set(encoded, forKey: "bestTimes")
        }
        if let encoded = try? JSONEncoder().encode(dailyChallengeStatuses) {
            UserDefaults.standard.set(encoded, forKey: dailyChallengeStatusKey)
        }
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
            records = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "bestTimes"),
           let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            bestTimes = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: dailyChallengeStatusKey),
           let decoded = try? JSONDecoder().decode([String: DailyChallengeStatus].self, from: data) {
            dailyChallengeStatuses = decoded
        }
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
        
        updateStats()
    }
}
