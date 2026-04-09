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
        let rows = difficulty == .custom ? customRows : difficulty.rows
        let cols = difficulty == .custom ? customCols : difficulty.cols
        let mines = difficulty == .custom ? customMines : difficulty.mineCount
        
        gameBoard = GameBoard(rows: rows, cols: cols, mineCount: mines)
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
        customRows = max(5, min(30, rows))
        customCols = max(5, min(30, cols))
        let maxMines = (customRows * customCols) - 9
        customMines = max(1, min(maxMines, mines))
        saveSettings()
        
        if presetNameDraft.isEmpty {
            presetNameDraft = defaultPresetName
        }
        
        if difficulty == .custom {
            updateBoardSize()
        }
    }
    
    private func configureChallengeDefaultsIfNeeded() {
        switch challengeMode {
        case .none:
            challengeSecondsRemaining = 0
        case .daily:
            difficulty = .medium
        case .timed:
            difficulty = .medium
            challengeSecondsRemaining = timedChallengeLimit
        case .noGuess:
            difficulty = .easy
        }
    }
    
    var defaultPresetName: String {
        "自定义 \(customRows)×\(customCols)"
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
        
        hintPosition = gameBoard.getHint()
        isShowingHint = hintPosition != nil
        
        if isShowingHint {
            hapticManager.impact(.light)
            // 3秒后自动隐藏提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.isShowingHint = false
            }
        }
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
