import Foundation
import Combine

// 使用 @MainActor 确保在主线程更新 UI
@MainActor
class GameBoard: ObservableObject {
    // 使用 @Published 但优化更新频率
    @Published private(set) var cells: [[Cell]]
    @Published private(set) var gameState: GameState = .playing
    @Published private(set) var flagCount: Int = 0
    @Published private(set) var revealedCount: Int = 0
    
    let rows: Int
    let cols: Int
    let totalMines: Int
    
    private var firstMove: Bool = true
    private var minePositions: Set<Int> = [] // 使用 Int 而不是 String，性能更好
    private var neighborCache: [[Int]] = [] // 缓存邻居位置
    
    // 用于批量更新，减少 UI 刷新
    private var pendingUpdates: Set<String> = []
    private var updateTimer: Timer?
    
    enum GameState: Equatable {
        case playing
        case won
        case lost
    }
    
    init(rows: Int, cols: Int, mineCount: Int) {
        self.rows = rows
        self.cols = cols
        self.totalMines = mineCount
        self.cells = Array(repeating: Array(repeating: Cell(row: 0, col: 0), count: cols), count: rows)
        initializeBoard()
        precomputeNeighbors()
    }
    
    // MARK: - 初始化
    
    private func initializeBoard() {
        for row in 0..<rows {
            for col in 0..<cols {
                cells[row][col] = Cell(row: row, col: col)
            }
        }
    }
    
    // 预计算邻居位置，避免重复计算
    private func precomputeNeighbors() {
        neighborCache = Array(repeating: Array(repeating: 0, count: 8), count: rows * cols)
        
        for row in 0..<rows {
            for col in 0..<cols {
                let index = row * cols + col
                var neighbors: [Int] = []
                
                for dr in -1...1 {
                    for dc in -1...1 {
                        if dr == 0 && dc == 0 { continue }
                        let nr = row + dr
                        let nc = col + dc
                        if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
                            neighbors.append(nr * cols + nc)
                        }
                    }
                }
                
                // 存储邻居数量（用于快速访问）
                neighborCache[index] = neighbors
            }
        }
    }
    
    // MARK: - 地雷放置
    
    private func placeMines(excludingRow: Int, excludingCol: Int) {
        minePositions.removeAll()
        
        // 使用 Fisher-Yates 洗牌算法的变体来高效放置地雷
        var availablePositions: [Int] = []
        
        for row in 0..<rows {
            for col in 0..<cols {
                // 排除第一点击位置及其周围
                let isExcludedArea = abs(row - excludingRow) <= 1 && abs(col - excludingCol) <= 1
                if !isExcludedArea {
                    availablePositions.append(row * cols + col)
                }
            }
        }
        
        // 随机选择地雷位置
        for i in 0..<min(totalMines, availablePositions.count) {
            let randomIndex = Int.random(in: i..<availablePositions.count)
            let position = availablePositions[randomIndex]
            minePositions.insert(position)
            
            // 交换位置
            availablePositions.swapAt(i, randomIndex)
        }
        
        // 设置地雷
        for position in minePositions {
            let row = position / cols
            let col = position % cols
            cells[row][col] = Cell(row: row, col: col, isMine: true)
        }
        
        calculateNeighborMines()
    }
    
    private func calculateNeighborMines() {
        for row in 0..<rows {
            for col in 0..<cols {
                if cells[row][col].isMine { continue }
                
                let index = row * cols + col
                let neighbors = neighborCache[index]
                var count = 0
                
                for neighborIndex in neighbors {
                    let nr = neighborIndex / cols
                    let nc = neighborIndex % cols
                    if cells[nr][nc].isMine {
                        count += 1
                    }
                }
                
                cells[row][col] = Cell(
                    row: row,
                    col: col,
                    isMine: false,
                    neighborMines: count,
                    state: .hidden
                )
            }
        }
    }
    
    // MARK: - 游戏操作
    
    func revealCell(row: Int, col: Int) -> Bool {
        guard isValidPosition(row: row, col: col) else { return false }
        guard cells[row][col].isHidden else { return false }
        
        // 第一次点击时放置地雷
        if firstMove {
            firstMove = false
            placeMines(excludingRow: row, excludingCol: col)
        }
        
        // 使用栈代替队列，减少内存分配
        var stack: [(Int, Int)] = [(row, col)]
        var visited = Set<Int>()
        var revealedCells: [(Int, Int)] = []
        
        while !stack.isEmpty {
            let (currentRow, currentCol) = stack.removeLast()
            let index = currentRow * cols + currentCol
            
            guard !visited.contains(index) else { continue }
            visited.insert(index)
            
            guard isValidPosition(row: currentRow, col: currentCol) else { continue }
            guard cells[currentRow][currentCol].isHidden else { continue }
            
            // 更新单元格状态
            cells[currentRow][currentCol].state = .revealed
            revealedCells.append((currentRow, currentCol))
            
            // 如果点击到地雷，游戏结束
            if cells[currentRow][currentCol].isMine {
                cells[currentRow][currentCol].state = .exploded
                gameState = .lost
                revealAllMines()
                return true // 返回 true 表示触发了爆炸
            }
            
            // 如果是空白单元格，自动展开周围
            if cells[currentRow][currentCol].neighborMines == 0 {
                let neighbors = neighborCache[index]
                for neighborIndex in neighbors {
                    let nr = neighborIndex / cols
                    let nc = neighborIndex % cols
                    if cells[nr][nc].isHidden && !visited.contains(neighborIndex) {
                        stack.append((nr, nc))
                    }
                }
            }
        }
        
        // 批量更新计数
        revealedCount += revealedCells.count
        
        checkWinCondition()
        return false
    }
    
    func toggleFlag(row: Int, col: Int) {
        guard isValidPosition(row: row, col: col) else { return }
        
        switch cells[row][col].state {
        case .hidden:
            cells[row][col].state = .flagged
            flagCount += 1
        case .flagged:
            cells[row][col].state = .questioned
            flagCount -= 1
        case .questioned:
            cells[row][col].state = .hidden
        default:
            break
        }
    }
    
    func quickReveal(row: Int, col: Int) -> Bool {
        guard isValidPosition(row: row, col: col) else { return false }
        guard cells[row][col].isRevealed && cells[row][col].neighborMines > 0 else { return false }
        
        let index = row * cols + col
        let neighbors = neighborCache[index]
        
        var flagCount = 0
        var hiddenCells: [(Int, Int)] = []
        
        for neighborIndex in neighbors {
            let nr = neighborIndex / cols
            let nc = neighborIndex % cols
            if cells[nr][nc].isFlagged {
                flagCount += 1
            } else if cells[nr][nc].isHidden {
                hiddenCells.append((nr, nc))
            }
        }
        
        // 如果标记数等于周围地雷数，自动展开其他隐藏单元格
        if flagCount == cells[row][col].neighborMines && !hiddenCells.isEmpty {
            var exploded = false
            for (r, c) in hiddenCells {
                if revealCell(row: r, col: c) {
                    exploded = true
                }
            }
            return exploded
        }
        
        return false
    }
    
    // MARK: - 提示功能
    
    func getHint() -> (row: Int, col: Int)? {
        // 优先找确定安全的单元格
        for row in 0..<rows {
            for col in 0..<cols {
                if cells[row][col].isHidden && !cells[row][col].isFlagged {
                    let index = row * cols + col
                    let neighbors = neighborCache[index]
                    
                    // 检查是否有邻居数字已被满足
                    var isSafe = false
                    for neighborIndex in neighbors {
                        let nr = neighborIndex / cols
                        let nc = neighborIndex % cols
                        
                        if cells[nr][nc].isRevealed && cells[nr][nc].neighborMines > 0 {
                            let flagCount = getFlaggedNeighborCount(row: nr, col: nc)
                            if flagCount >= cells[nr][nc].neighborMines {
                                isSafe = true
                                break
                            }
                        }
                    }
                    
                    if isSafe {
                        return (row, col)
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
                    let probability = calculateMineProbability(row: row, col: col)
                    if probability < bestProbability {
                        bestProbability = probability
                        bestCell = (row, col)
                    }
                }
            }
        }
        
        return bestCell
    }
    
    private func getFlaggedNeighborCount(row: Int, col: Int) -> Int {
        let index = row * cols + col
        let neighbors = neighborCache[index]
        var count = 0
        
        for neighborIndex in neighbors {
            let nr = neighborIndex / cols
            let nc = neighborIndex % cols
            if cells[nr][nc].isFlagged {
                count += 1
            }
        }
        
        return count
    }
    
    private func getHiddenNeighborCount(row: Int, col: Int) -> Int {
        let index = row * cols + col
        let neighbors = neighborCache[index]
        var count = 0
        
        for neighborIndex in neighbors {
            let nr = neighborIndex / cols
            let nc = neighborIndex % cols
            if cells[nr][nc].isHidden {
                count += 1
            }
        }
        
        return count
    }
    
    private func calculateMineProbability(row: Int, col: Int) -> Double {
        let index = row * cols + col
        let neighbors = neighborCache[index]
        var totalProbability: Double = 0
        var count = 0
        
        for neighborIndex in neighbors {
            let nr = neighborIndex / cols
            let nc = neighborIndex % cols
            
            if cells[nr][nc].isRevealed && cells[nr][nc].neighborMines > 0 {
                let hiddenCount = getHiddenNeighborCount(row: nr, col: nc)
                let flagCount = getFlaggedNeighborCount(row: nr, col: nc)
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
    
    // MARK: - 游戏状态
    
    private func revealAllMines() {
        for row in 0..<rows {
            for col in 0..<cols {
                if cells[row][col].isMine && cells[row][col].state != .exploded {
                    cells[row][col].state = .revealed
                }
            }
        }
    }
    
    private func checkWinCondition() {
        let totalCells = rows * cols
        let nonMineCells = totalCells - totalMines
        
        if revealedCount >= nonMineCells {
            gameState = .won
            // 自动标记所有未标记的地雷
            for row in 0..<rows {
                for col in 0..<cols {
                    if cells[row][col].isMine && cells[row][col].isHidden {
                        cells[row][col].state = .flagged
                    }
                }
            }
            flagCount = totalMines
        }
    }
    
    func reset() {
        firstMove = true
        gameState = .playing
        flagCount = 0
        revealedCount = 0
        minePositions.removeAll()
        initializeBoard()
    }
    
    func getRemainingMines() -> Int {
        return totalMines - flagCount
    }
    
    private func isValidPosition(row: Int, col: Int) -> Bool {
        return row >= 0 && row < rows && col >= 0 && col < cols
    }
    
    // MARK: - 状态快照（用于撤销）
    
    func createSnapshot(elapsedTime: TimeInterval) -> GameStateSnapshot {
        let cellData = cells.flatMap { row in
            row.map { cell in
                GameStateSnapshot.CellData(
                    row: cell.row,
                    col: cell.col,
                    isMine: cell.isMine,
                    neighborMines: cell.neighborMines,
                    state: cellStateToString(cell.state)
                )
            }
        }
        
        return GameStateSnapshot(
            cells: cellData,
            gameState: gameStateToString(gameState),
            flagCount: flagCount,
            revealedCount: revealedCount,
            elapsedTime: elapsedTime,
            timestamp: Date()
        )
    }
    
    func restore(from snapshot: GameStateSnapshot) {
        // 恢复单元格
        for cellData in snapshot.cells {
            let row = cellData.row
            let col = cellData.col
            if isValidPosition(row: row, col: col) {
                cells[row][col] = Cell(
                    row: row,
                    col: col,
                    isMine: cellData.isMine,
                    neighborMines: cellData.neighborMines,
                    state: stringToCellState(cellData.state)
                )
            }
        }
        
        // 恢复游戏状态
        flagCount = snapshot.flagCount
        revealedCount = snapshot.revealedCount
        gameState = stringToGameState(snapshot.gameState)
        firstMove = false // 恢复后不再是第一次移动
    }
    
    private func cellStateToString(_ state: CellState) -> String {
        switch state {
        case .hidden: return "hidden"
        case .revealed: return "revealed"
        case .flagged: return "flagged"
        case .questioned: return "questioned"
        case .exploded: return "exploded"
        }
    }
    
    private func stringToCellState(_ string: String) -> CellState {
        switch string {
        case "revealed": return .revealed
        case "flagged": return .flagged
        case "questioned": return .questioned
        case "exploded": return .exploded
        default: return .hidden
        }
    }
    
    private func gameStateToString(_ state: GameState) -> String {
        switch state {
        case .playing: return "playing"
        case .won: return "won"
        case .lost: return "lost"
        }
    }
    
    private func stringToGameState(_ string: String) -> GameState {
        switch string {
        case "won": return .won
        case "lost": return .lost
        default: return .playing
        }
    }
}
