import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameBoard: GameBoard
    @Published var difficulty: Difficulty = .easy
    @Published var elapsedTime: TimeInterval = 0
    @Published var isGameActive: Bool = false
    @Published var showGameOverAlert: Bool = false
    @Published var showWinAlert: Bool = false
    @Published var customRows: Int = 16
    @Published var customCols: Int = 16
    @Published var customMines: Int = 40
    
    // 新增功能状态
    @Published var isPaused: Bool = false
    @Published var canUndo: Bool = false
    @Published var showPauseOverlay: Bool = false
    @Published var hintPosition: (row: Int, col: Int)? = nil
    @Published var hintMessage: String = ""
    @Published var hintKind: HintDescriptor.Kind = .none
    @Published var isShowingHint: Bool = false
    @Published var hasSavedGame: Bool = false
    @Published var customPresets: [CustomPreset] = []
    @Published var presetNameDraft: String = ""
    @Published var challengeMode: ChallengeMode = .none
    @Published var challengeSecondsRemaining: Int = 0
    
    let gameStats = GameStats()
    let soundManager = SoundManager.shared
    let hapticManager = HapticManager.shared
    let themeManager = ThemeManager.shared
    let gameStateManager = GameStateManager.shared
    let animationManager = AnimationManager.shared
    
    private var timer: Timer?
    private var startTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private let customPresetsKey = "customPresets"
    private let challengeModeKey = "challengeMode"
    private let timedChallengeLimit = 180
    private var boardSeed: UInt64?
    private var boardSafeRadius: Int = 1
    private var requireLogicalSolvableBoard: Bool = false
    
    init() {
        self.gameBoard = GameBoard(rows: Difficulty.easy.rows, 
                                   cols: Difficulty.easy.cols, 
                                   mineCount: Difficulty.easy.mineCount)
        loadSettings()
        loadCustomPresets()
        checkSavedGame()
    }
    
    // MARK: - 设置加载
    
    private func loadSettings() {
        if let savedDifficulty = UserDefaults.standard.string(forKey: "selectedDifficulty"),
           let diff = Difficulty(rawValue: savedDifficulty) {
            difficulty = diff
            updateBoardSize()
        }
        if let savedChallengeMode = UserDefaults.standard.string(forKey: challengeModeKey),
           let mode = ChallengeMode(rawValue: savedChallengeMode) {
            challengeMode = mode
        }
        customRows = UserDefaults.standard.integer(forKey: "customRows")
        if customRows == 0 { customRows = 16 }
        customCols = UserDefaults.standard.integer(forKey: "customCols")
        if customCols == 0 { customCols = 16 }
        customMines = UserDefaults.standard.integer(forKey: "customMines")
        if customMines == 0 { customMines = 40 }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(difficulty.rawValue, forKey: "selectedDifficulty")
        UserDefaults.standard.set(customRows, forKey: "customRows")
        UserDefaults.standard.set(customCols, forKey: "customCols")
        UserDefaults.standard.set(customMines, forKey: "customMines")
        UserDefaults.standard.set(challengeMode.rawValue, forKey: challengeModeKey)
    }
    
    private func loadCustomPresets() {
        guard let data = UserDefaults.standard.data(forKey: customPresetsKey),
              let decoded = try? JSONDecoder().decode([CustomPreset].self, from: data) else {
            customPresets = []
            return
        }
        customPresets = decoded
    }
    
    private func saveCustomPresets() {
        if let data = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(data, forKey: customPresetsKey)
        }
    }
    
    // MARK: - 游戏板管理
    
    func updateBoardSize() {
        configureChallengeDefaultsIfNeeded()
        let rows = difficulty == .custom ? customRows : difficulty.rows
        let cols = difficulty == .custom ? customCols : difficulty.cols
        let mines = difficulty == .custom ? customMines : difficulty.mineCount
        
        gameBoard = GameBoard(rows: rows, cols: cols, mineCount: mines, seed: boardSeed, safeRadius: boardSafeRadius, requireLogicalSolvable: requireLogicalSolvableBoard)
        resetTimer()
        if challengeMode == .timed {
            challengeSecondsRemaining = timedChallengeLimit
        }
        isGameActive = false
        showGameOverAlert = false
        showWinAlert = false
        isPaused = false
        showPauseOverlay = false
        canUndo = false
        hintPosition = nil
        gameStateManager.clearUndoStack()
        gameStateManager.clearSavedGame()
        hasSavedGame = false
    }
    
    func setDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        saveSettings()
        updateBoardSize()
    }
    
    func setChallengeMode(_ mode: ChallengeMode) {
        challengeMode = mode
        saveSettings()
        configureChallengeDefaultsIfNeeded()
        updateBoardSize()
    }
    
    func updateCustomSettings(rows: Int, cols: Int, mines: Int) {
        let newRows = max(5, min(30, rows))
        let newCols = max(5, min(30, cols))
        let maxMines = max(1, (newRows * newCols) - 9)
        let newMines = max(1, min(maxMines, mines))
        
        let didChange = newRows != customRows || newCols != customCols || newMines != customMines
        customRows = newRows
        customCols = newCols
        customMines = newMines
        saveSettings()
        
        if presetNameDraft.isEmpty {
            presetNameDraft = defaultPresetName
        }
        
        if difficulty == .custom && didChange {
            gameBoard = GameBoard(rows: customRows, cols: customCols, mineCount: customMines, seed: boardSeed, safeRadius: boardSafeRadius, requireLogicalSolvable: requireLogicalSolvableBoard)
            resetTimer()
            if challengeMode == .timed {
                challengeSecondsRemaining = timedChallengeLimit
            }
            isGameActive = false
            showGameOverAlert = false
            showWinAlert = false
            isPaused = false
            showPauseOverlay = false
            canUndo = false
            hintPosition = nil
            isShowingHint = false
            gameStateManager.clearUndoStack()
            gameStateManager.clearSavedGame()
            hasSavedGame = false
        }
    }
    
    private func configureChallengeDefaultsIfNeeded() {
        boardSeed = nil
        boardSafeRadius = 1
        requireLogicalSolvableBoard = false
        
        switch challengeMode {
        case .none:
            challengeSecondsRemaining = 0
        case .daily:
            boardSeed = stableDailySeed()
        case .timed:
            challengeSecondsRemaining = timedChallengeLimit
        case .noGuess:
            boardSafeRadius = 2
            requireLogicalSolvableBoard = true
        }
    }
    
    var defaultPresetName: String {
        "自定义 \(customRows)×\(customCols)"
    }
    
    var customMineDensity: Double {
        let total = max(1, customRows * customCols)
        return Double(customMines) / Double(total)
    }
    
    func saveCurrentAsPreset() {
        let trimmed = presetNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? defaultPresetName : trimmed
        let preset = CustomPreset(name: name, rows: customRows, cols: customCols, mines: customMines)
        customPresets.insert(preset, at: 0)
        if customPresets.count > 12 {
            customPresets = Array(customPresets.prefix(12))
        }
        presetNameDraft = name
        saveCustomPresets()
    }
    
    func applyCustomPreset(_ preset: CustomPreset) {
        presetNameDraft = preset.name
        customRows = preset.rows
        customCols = preset.cols
        customMines = preset.mines
        difficulty = .custom
        saveSettings()
        updateBoardSize()
    }
    
    func deleteCustomPreset(_ preset: CustomPreset) {
        customPresets.removeAll { $0.id == preset.id }
        saveCustomPresets()
    }
    
    // MARK: - 游戏操作
    
    func revealCell(row: Int, col: Int) {
        guard gameBoard.gameState == .playing && !isPaused else { return }
        guard gameBoard.cells[row][col].isHidden else { return }
        
        // 保存状态用于撤销
        if isGameActive {
            saveStateForUndo()
        }
        
        if !isGameActive {
            startTimer()
            isGameActive = true
        }
        
        // 清除提示
        hintPosition = nil
        hintMessage = ""
        hintKind = .none
        isShowingHint = false
        
        let exploded = gameBoard.revealCell(row: row, col: col)
        
        if exploded {
            // 触发爆炸动画
            let position = getCellPosition(row: row, col: col)
            animationManager.triggerExplosion(at: position, in: UIScreen.main.bounds.size)
        }
        
        soundManager.playClick()
        hapticManager.cellTapped()
        
        checkGameState()
        
        // 自动保存
        if isGameActive {
            autoSave()
        }
    }
    
    func toggleFlag(row: Int, col: Int) {
        guard gameBoard.gameState == .playing && !isPaused else { return }
        
        // 保存状态用于撤销
        if isGameActive {
            saveStateForUndo()
        }
        
        gameBoard.toggleFlag(row: row, col: col)
        soundManager.playFlag()
        hapticManager.cellFlagged()
        
        // 自动保存
        if isGameActive {
            autoSave()
        }
    }
    
    func quickReveal(row: Int, col: Int) {
        guard gameBoard.gameState == .playing && !isPaused else { return }
        
        // 保存状态用于撤销
        if isGameActive {
            saveStateForUndo()
        }
        
        let exploded = gameBoard.quickReveal(row: row, col: col)
        
        if exploded {
            let position = getCellPosition(row: row, col: col)
            animationManager.triggerExplosion(at: position, in: UIScreen.main.bounds.size)
        }
        
        soundManager.playClick()
        checkGameState()
        
        // 自动保存
        if isGameActive {
            autoSave()
        }
    }
    
    // MARK: - 撤销功能
    
    private func saveStateForUndo() {
        gameStateManager.pushState(
            cells: gameBoard.cells,
            gameState: gameBoard.gameState,
            flagCount: gameBoard.flagCount,
            revealedCount: gameBoard.revealedCount,
            elapsedTime: elapsedTime
        )
        canUndo = gameStateManager.canUndo
    }
    
    func undo() {
        guard let snapshot = gameStateManager.popState() else { return }
        
        gameBoard.restore(from: snapshot)
        elapsedTime = snapshot.elapsedTime
        canUndo = gameStateManager.canUndo
        hintPosition = nil
        isShowingHint = false
        
        hapticManager.impact(.light)
    }
    
    // MARK: - 暂停功能
    
    func togglePause() {
        if isPaused {
            resumeGame()
        } else {
            pauseGame()
        }
    }
    
    func pauseGame() {
        guard isGameActive && gameBoard.gameState == .playing else { return }
        
        isPaused = true
        showPauseOverlay = true
        pauseStartTime = Date()
        stopTimer()
        
        hapticManager.impact(.medium)
    }
    
    func resumeGame() {
        isPaused = false
        showPauseOverlay = false
        
        // 累加暂停时间
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
            pauseStartTime = nil
        }
        
        // 恢复计时器
        if isGameActive {
            startTimer()
        }
        
        hapticManager.impact(.light)
    }
    
    // MARK: - 提示功能
    
    func showHint() {
        guard gameBoard.gameState == .playing && !isPaused else { return }
        
        let descriptor = computeHintDescriptor()
        hintPosition = descriptor.position
        hintMessage = descriptor.message
        hintKind = descriptor.kind
        isShowingHint = descriptor.position != nil
        
        if isShowingHint {
            hapticManager.impact(.light)
            // 3秒后自动隐藏提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.isShowingHint = false
                self?.hintMessage = ""
                self?.hintKind = .none
            }
        }
    }
    
    private func computeHintDescriptor() -> HintDescriptor {
        if let flagTarget = findFlagRecommendation() {
            return HintDescriptor(position: flagTarget, message: "已高亮建议标雷的位置", kind: .flag)
        }
        
        guard let position = gameBoard.getHint() else {
            return HintDescriptor(position: nil, message: "当前没有可用提示", kind: .none)
        }
        
        let hasSafeNeighbor = safeHintConfidence(row: position.row, col: position.col)
        if hasSafeNeighbor {
            return HintDescriptor(position: position, message: "已高亮确定安全的位置", kind: .safe)
        }
        
        return HintDescriptor(
            position: position,
            message: challengeMode == .noGuess ? "已高亮低风险逻辑位" : "已高亮建议点击位置（有一定风险）",
            kind: .risky
        )
    }
    
    private func findFlagRecommendation() -> (row: Int, col: Int)? {
        for row in 0..<gameBoard.rows {
            for col in 0..<gameBoard.cols {
                let cell = gameBoard.cells[row][col]
                guard cell.isRevealed && cell.neighborMines > 0 else { continue }
                
                var hiddenNeighbors: [(Int, Int)] = []
                var flaggedCount = 0
                
                for dr in -1...1 {
                    for dc in -1...1 {
                        if dr == 0 && dc == 0 { continue }
                        let nr = row + dr
                        let nc = col + dc
                        guard nr >= 0 && nr < gameBoard.rows && nc >= 0 && nc < gameBoard.cols else { continue }
                        let neighbor = gameBoard.cells[nr][nc]
                        if neighbor.isFlagged {
                            flaggedCount += 1
                        } else if neighbor.isHidden {
                            hiddenNeighbors.append((nr, nc))
                        }
                    }
                }
                
                if !hiddenNeighbors.isEmpty && hiddenNeighbors.count + flaggedCount == cell.neighborMines {
                    return hiddenNeighbors.first
                }
            }
        }
        return nil
    }
    
    private func safeHintConfidence(row: Int, col: Int) -> Bool {
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nr = row + dr
                let nc = col + dc
                guard nr >= 0 && nr < gameBoard.rows && nc >= 0 && nc < gameBoard.cols else { continue }
                let neighbor = gameBoard.cells[nr][nc]
                if neighbor.isRevealed && neighbor.neighborMines > 0 {
                    var flagged = 0
                    for rr in -1...1 {
                        for cc in -1...1 {
                            if rr == 0 && cc == 0 { continue }
                            let ar = nr + rr
                            let ac = nc + cc
                            guard ar >= 0 && ar < gameBoard.rows && ac >= 0 && ac < gameBoard.cols else { continue }
                            if gameBoard.cells[ar][ac].isFlagged {
                                flagged += 1
                            }
                        }
                    }
                    if flagged >= neighbor.neighborMines {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // MARK: - 自动保存
    
    func autoSave() {
        let snapshot = gameBoard.createSnapshot(elapsedTime: elapsedTime)
        gameStateManager.saveGame(
            difficulty: difficulty,
            rows: gameBoard.rows,
            cols: gameBoard.cols,
            mineCount: gameBoard.totalMines,
            snapshot: snapshot
        )
    }
    
    func checkSavedGame() {
        hasSavedGame = gameStateManager.hasSavedGame()
    }
    
    func loadSavedGame() -> Bool {
        guard let savedGame = gameStateManager.loadSavedGame() else { return false }
        
        // 恢复难度设置
        if let savedDifficulty = Difficulty(rawValue: savedGame.difficulty) {
            difficulty = savedDifficulty
        }
        
        // 创建新的游戏板
        gameBoard = GameBoard(rows: savedGame.rows, cols: savedGame.cols, mineCount: savedGame.mineCount)
        
        // 恢复游戏状态
        gameBoard.restore(from: savedGame.snapshot)
        elapsedTime = savedGame.snapshot.elapsedTime
        isGameActive = true
        canUndo = false
        
        // 恢复计时器
        startTimer()
        
        return true
    }
    
    func clearSavedGame() {
        gameStateManager.clearSavedGame()
        hasSavedGame = false
    }
    
    // MARK: - 游戏状态检查
    
    private func checkGameState() {
        switch gameBoard.gameState {
        case .won:
            stopTimer()
            soundManager.playWin()
            hapticManager.gameWon()
            showWinAlert = true
            isGameActive = false
            
            // 触发胜利动画
            animationManager.triggerWinAnimation(in: UIScreen.main.bounds.size)
            
            // 记录游戏结果
            gameStats.addRecord(
                difficulty: difficulty,
                challengeMode: challengeMode,
                generationQuality: challengeMode == .noGuess ? gameBoard.generationQualityNote : nil,
                result: .won,
                duration: elapsedTime,
                rows: gameBoard.rows,
                cols: gameBoard.cols,
                mineCount: gameBoard.totalMines
            )
            
            // 清除自动保存
            clearSavedGame()
            
        case .lost:
            stopTimer()
            soundManager.playLose()
            hapticManager.gameLost()
            showGameOverAlert = true
            isGameActive = false
            
            // 记录游戏结果
            gameStats.addRecord(
                difficulty: difficulty,
                challengeMode: challengeMode,
                generationQuality: challengeMode == .noGuess ? gameBoard.generationQualityNote : nil,
                result: .lost,
                duration: elapsedTime,
                rows: gameBoard.rows,
                cols: gameBoard.cols,
                mineCount: gameBoard.totalMines
            )
            
            // 清除自动保存
            clearSavedGame()
            
        case .playing:
            break
        }
        
        canUndo = gameStateManager.canUndo
    }
    
    func newGame() {
        gameBoard.reset()
        resetTimer()
        isGameActive = false
        isPaused = false
        showPauseOverlay = false
        showGameOverAlert = false
        showWinAlert = false
        canUndo = false
        hintPosition = nil
        isShowingHint = false
        gameStateManager.clearUndoStack()
        clearSavedGame()
        animationManager.stopAllAnimations()
    }
    
    // MARK: - 计时器
    
    private func startTimer() {
        startTime = Date().addingTimeInterval(-elapsedTime)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        elapsedTime = 0
        startTime = nil
        pauseStartTime = nil
        totalPausedTime = 0
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime) - totalPausedTime
        
        if challengeMode == .timed {
            challengeSecondsRemaining = max(0, timedChallengeLimit - Int(elapsedTime))
            if challengeSecondsRemaining == 0 && gameBoard.gameState == .playing && isGameActive {
                stopTimer()
                showGameOverAlert = true
                isGameActive = false
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func getCellPosition(row: Int, col: Int) -> CGPoint {
        // 返回单元格的中心位置（用于动画）
        // 这里简化处理，实际应该根据视图布局计算
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let cellSize = min(
            (screenWidth - 32) / CGFloat(gameBoard.cols),
            (screenHeight - 200) / CGFloat(gameBoard.rows),
            50
        )
        
        let boardWidth = cellSize * CGFloat(gameBoard.cols) + 2 * CGFloat(gameBoard.cols - 1)
        let boardHeight = cellSize * CGFloat(gameBoard.rows) + 2 * CGFloat(gameBoard.rows - 1)
        
        let startX = (screenWidth - boardWidth) / 2
        let startY = (screenHeight - boardHeight) / 2 + 50
        
        return CGPoint(
            x: startX + CGFloat(col) * (cellSize + 2) + cellSize / 2,
            y: startY + CGFloat(row) * (cellSize + 2) + cellSize / 2
        )
    }
    
    // MARK: - 格式化
    
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var remainingMines: Int {
        gameBoard.getRemainingMines()
    }
}
