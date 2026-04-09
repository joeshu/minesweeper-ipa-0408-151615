import Foundation
import Combine

// 游戏状态快照，用于撤销功能
struct GameStateSnapshot: Codable {
    let cells: [CellData]
    let gameState: String
    let flagCount: Int
    let revealedCount: Int
    let elapsedTime: TimeInterval
    let timestamp: Date
    
    struct CellData: Codable {
        let row: Int
        let col: Int
        let isMine: Bool
        let neighborMines: Int
        let state: String
    }
}

// 保存的游戏数据
struct SavedGame: Codable {
    let difficulty: String
    let rows: Int
    let cols: Int
    let mineCount: Int
    let snapshot: GameStateSnapshot
    let saveDate: Date
}

class GameStateManager: ObservableObject {
    static let shared = GameStateManager()
    
    @Published var isPaused: Bool = false
    @Published var canUndo: Bool = false
    
    private var undoStack: [GameStateSnapshot] = []
    private let maxUndoSteps = 3
    private let savedGameKey = "savedGame"
    
    private init() {}
    
    // MARK: - 撤销功能
    
    func pushState(cells: [[Cell]], gameState: GameBoard.GameState, flagCount: Int, revealedCount: Int, elapsedTime: TimeInterval) {
        let snapshot = createSnapshot(
            cells: cells,
            gameState: gameState,
            flagCount: flagCount,
            revealedCount: revealedCount,
            elapsedTime: elapsedTime
        )
        
        undoStack.append(snapshot)
        
        // 限制撤销步数
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        updateCanUndo()
    }
    
    func popState() -> GameStateSnapshot? {
        guard !undoStack.isEmpty else { return nil }
        let snapshot = undoStack.removeLast()
        updateCanUndo()
        return snapshot
    }
    
    func clearUndoStack() {
        undoStack.removeAll()
        updateCanUndo()
    }
    
    private func updateCanUndo() {
        canUndo = !undoStack.isEmpty
    }
    
    private func createSnapshot(cells: [[Cell]], gameState: GameBoard.GameState, flagCount: Int, revealedCount: Int, elapsedTime: TimeInterval) -> GameStateSnapshot {
        let cellData = cells.flatMap { row in
            row.map { cell in
                GameStateSnapshot.CellData(
                    row: cell.row,
                    col: cell.col,
                    isMine: cell.isMine,
                    neighborMines: cell.neighborMines,
                    state: String(describing: cell.state)
                )
            }
        }
        
        return GameStateSnapshot(
            cells: cellData,
            gameState: String(describing: gameState),
            flagCount: flagCount,
            revealedCount: revealedCount,
            elapsedTime: elapsedTime,
            timestamp: Date()
        )
    }
    
    // MARK: - 暂停功能
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    // MARK: - 自动保存功能
    
    func saveGame(difficulty: Difficulty, rows: Int, cols: Int, mineCount: Int, snapshot: GameStateSnapshot) {
        let savedGame = SavedGame(
            difficulty: difficulty.rawValue,
            rows: rows,
            cols: cols,
            mineCount: mineCount,
            snapshot: snapshot,
            saveDate: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(savedGame) {
            UserDefaults.standard.set(encoded, forKey: savedGameKey)
        }
    }
    
    func loadSavedGame() -> SavedGame? {
        guard let data = UserDefaults.standard.data(forKey: savedGameKey) else { return nil }
        return try? JSONDecoder().decode(SavedGame.self, from: data)
    }
    
    func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: savedGameKey)
    }
    
    func hasSavedGame() -> Bool {
        return UserDefaults.standard.data(forKey: savedGameKey) != nil
    }
    
    // MARK: - 提示功能
    
    func getHint(cells: [[Cell]], rows: Int, cols: Int) -> (row: Int, col: Int)? {
        // 优先找确定安全的单元格
        for row in 0..<rows {
            for col in 0..<cols {
                if cells[row][col].isHidden {
                    // 检查周围是否有已揭示的单元格
                    let neighbors = getNeighbors(row: row, col: col, rows: rows, cols: cols)
                    var hasRevealedNeighbor = false
                    var isDefinitelySafe = true
                    
                    for (nr, nc) in neighbors {
                        if cells[nr][nc].isRevealed && cells[nr][nc].neighborMines > 0 {
                            hasRevealedNeighbor = true
                            // 如果邻居周围还有未标记的隐藏单元格，不确定是否安全
                            let neighborHiddenCount = getHiddenNeighborsCount(cells: cells, row: nr, col: nc, rows: rows, cols: cols)
                            let neighborFlagCount = getFlaggedNeighborsCount(cells: cells, row: nr, col: nc, rows: rows, cols: cols)
                            if neighborHiddenCount > cells[nr][nc].neighborMines - neighborFlagCount {
                                isDefinitelySafe = false
                            }
                        }
                    }
                    
                    // 如果周围没有地雷邻居，则安全
                    if hasRevealedNeighbor && isDefinitelySafe {
                        // 进一步验证：检查所有邻居的数字是否都被满足
                        var allNeighborsSatisfied = true
                        for (nr, nc) in neighbors {
                            if cells[nr][nc].isRevealed && cells[nr][nc].neighborMines > 0 {
                                let flagCount = getFlaggedNeighborsCount(cells: cells, row: nr, col: nc, rows: rows, cols: cols)
                                if flagCount < cells[nr][nc].neighborMines {
                                    allNeighborsSatisfied = false
                                    break
                                }
                            }
                        }
                        
                        if allNeighborsSatisfied {
                            return (row, col)
                        }
                    }
                }
            }
        }
        
        // 如果没有确定安全的，找概率最低的
        var bestCell: (row: Int, col: Int)?
        var bestProbability: Double = 1.0
        
        for row in 0..<rows {
            for col in 0..<cols {
                if cells[row][col].isHidden && !cells[row][col].isFlagged {
                    let probability = calculateMineProbability(cells: cells, row: row, col: col, rows: rows, cols: cols)
                    if probability < bestProbability {
                        bestProbability = probability
                        bestCell = (row, col)
                    }
                }
            }
        }
        
        return bestCell
    }
    
    private func getNeighbors(row: Int, col: Int, rows: Int, cols: Int) -> [(Int, Int)] {
        var neighbors: [(Int, Int)] = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nr = row + dr
                let nc = col + dc
                if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                    neighbors.append((nr, nc))
                }
            }
        }
        return neighbors
    }
    
    private func getHiddenNeighborsCount(cells: [[Cell]], row: Int, col: Int, rows: Int, cols: Int) -> Int {
        let neighbors = getNeighbors(row: row, col: col, rows: rows, cols: cols)
        return neighbors.filter { cells[$0.0][$0.1].isHidden }.count
    }
    
    private func getFlaggedNeighborsCount(cells: [[Cell]], row: Int, col: Int, rows: Int, cols: Int) -> Int {
        let neighbors = getNeighbors(row: row, col: col, rows: rows, cols: cols)
        return neighbors.filter { cells[$0.0][$0.1].isFlagged }.count
    }
    
    private func calculateMineProbability(cells: [[Cell]], row: Int, col: Int, rows: Int, cols: Int) -> Double {
        let neighbors = getNeighbors(row: row, col: col, rows: rows, cols: cols)
        var totalProbability: Double = 0
        var count = 0
        
        for (nr, nc) in neighbors {
            if cells[nr][nc].isRevealed && cells[nr][nc].neighborMines > 0 {
                let hiddenCount = getHiddenNeighborsCount(cells: cells, row: nr, col: nc, rows: rows, cols: cols)
                let flagCount = getFlaggedNeighborsCount(cells: cells, row: nr, col: nc, rows: rows, cols: cols)
                let remainingMines = cells[nr][nc].neighborMines - flagCount
                
                if hiddenCount > 0 {
                    let probability = Double(remainingMines) / Double(hiddenCount)
                    totalProbability += probability
                    count += 1
                }
            }
        }
        
        return count > 0 ? totalProbability / Double(count) : 0.5
    }
}
