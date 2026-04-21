import Foundation
import Combine

// 使用 @MainActor 确保在主线程更新 UI
@MainActor
class GameBoard: ObservableObject {
    // 使用 @Published 但优化更新频率
    @Published private(set) var cells: [[Cell]]
    @Published private(set) var gameState: GameState = .playing
    @Published private(set) var flagCount: Int = 0
    var flaggedCount: Int { flagCount }
    @Published private(set) var revealedCount: Int = 0
    @Published private(set) var generationQualityNote: String = ""
    
    let rows: Int
    let cols: Int
    let totalMines: Int
    
    private var firstMove: Bool = true
    private var minePositions: Set<Int> = [] // 使用 Int 而不是 String，性能更好
    private var neighborCache: [[Int]] = [] // 缓存邻居位置
    private var forcedSeed: UInt64?
    private var expandedSafeRadius: Int = 1
    private var requireLogicalSolvable: Bool = false
    private var maxGenerationAttempts: Int = 60
    
    // 用于批量更新，减少 UI 刷新
    private var pendingUpdates: Set<String> = []
    private var updateTimer: Timer?
    
    enum GameState: Equatable {
        case playing
        case won
        case lost
    }
    
    init(rows: Int, cols: Int, mineCount: Int, seed: UInt64? = nil, safeRadius: Int = 1, requireLogicalSolvable: Bool = false) {
        self.rows = rows
        self.cols = cols
        self.totalMines = mineCount
        self.forcedSeed = seed
        self.expandedSafeRadius = max(1, safeRadius)
        self.requireLogicalSolvable = requireLogicalSolvable
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
        let baseSeed = forcedSeed ?? UInt64.random(in: 1...UInt64.max)
        let strategyRadii: [Int] = requireLogicalSolvable ? [expandedSafeRadius, expandedSafeRadius + 1, expandedSafeRadius + 2] : [expandedSafeRadius]
        
        for radius in strategyRadii {
            for attempt in 0..<maxGenerationAttempts {
                minePositions.removeAll()
                initializeBoard()
                
                // 使用 Fisher-Yates 洗牌算法的变体来高效放置地雷
                var availablePositions: [Int] = []
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        // 排除第一点击位置及其周围
                        let isExcludedArea = abs(row - excludingRow) <= radius && abs(col - excludingCol) <= radius
                        if !isExcludedArea {
                            availablePositions.append(row * cols + col)
                        }
                    }
                }
                
                var seededGenerator = SeededGenerator(seed: baseSeed &+ UInt64(attempt) &+ UInt64(radius * 10_000))
                
                // 随机选择地雷位置
                for i in 0..<min(totalMines, availablePositions.count) {
                    let randomIndex = Int.random(in: i..<availablePositions.count, using: &seededGenerator)
                    let position = availablePositions[randomIndex]
                    minePositions.insert(position)
                    availablePositions.swapAt(i, randomIndex)
                }
                
                // 设置地雷
                for position in minePositions {
                    let row = position / cols
                    let col = position % cols
                    cells[row][col] = Cell(row: row, col: col, isMine: true)
                }
                
                calculateNeighborMines()
                
                if !requireLogicalSolvable || isLogicallySolvable(startRow: excludingRow, startCol: excludingCol) {
                    generationQualityNote = radius == expandedSafeRadius ? "严格无猜盘面" : "回退增强盘面（扩大安全区）"
                    return
                }
            }
        }
        
        generationQualityNote = requireLogicalSolvable ? "未命中严格无猜，已使用回退策略" : "标准随机盘面"
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
    
    private func isLogicallySolvable(startRow: Int, startCol: Int) -> Bool {
        var revealed = Set<Int>()
        var flagged = Set<Int>()
        var queue: [Int] = [startRow * cols + startCol]
        
        while !queue.isEmpty {
            let current = queue.removeLast()
            if revealed.contains(current) { continue }
            revealed.insert(current)
            let row = current / cols
            let col = current % cols
            
            if cells[row][col].neighborMines == 0 {
                for neighbor in neighborCache[current] {
                    if !revealed.contains(neighbor) && !minePositions.contains(neighbor) {
                        queue.append(neighbor)
                    }
                }
            }
        }
        
        var changed = true
        while changed {
            changed = false
            
            for index in Array(revealed) {
                let row = index / cols
                let col = index % cols
                let cell = cells[row][col]
                guard cell.neighborMines > 0 else { continue }
                
                let neighbors = neighborCache[index]
                let hidden = neighbors.filter { !revealed.contains($0) && !flagged.contains($0) }
                let flaggedCount = neighbors.filter { flagged.contains($0) }.count
                let remainingMines = cell.neighborMines - flaggedCount
                
                if remainingMines == hidden.count && !hidden.isEmpty {
                    for item in hidden where !flagged.contains(item) {
                        flagged.insert(item)
                        changed = true
                    }
                } else if remainingMines == 0 && !hidden.isEmpty {
                    for item in hidden where !revealed.contains(item) && !minePositions.contains(item) {
                        if revealVirtualCell(item, revealed: &revealed) {
                            changed = true
                        }
                    }
                }
            }
            
            if applySubsetRule(revealed: &revealed, flagged: &flagged) {
                changed = true
            }
            
            if applyLocalEnumerationRule(revealed: &revealed, flagged: &flagged) {
                changed = true
            }
        }
        
        let nonMineCells = rows * cols - totalMines
        return revealed.count >= nonMineCells
    }
    
    private func revealVirtualCell(_ index: Int, revealed: inout Set<Int>) -> Bool {
        if revealed.contains(index) || minePositions.contains(index) { return false }
        var changed = false
        var stack: [Int] = [index]
        
        while !stack.isEmpty {
            let current = stack.removeLast()
            if revealed.contains(current) || minePositions.contains(current) { continue }
            revealed.insert(current)
            changed = true
            let row = current / cols
            let col = current % cols
            if cells[row][col].neighborMines == 0 {
                for neighbor in neighborCache[current] where !revealed.contains(neighbor) && !minePositions.contains(neighbor) {
                    stack.append(neighbor)
                }
            }
        }
        
        return changed
    }
    
    private func applySubsetRule(revealed: inout Set<Int>, flagged: inout Set<Int>) -> Bool {
        let numbered = Array(revealed).filter { idx in
            let row = idx / cols
            let col = idx % cols
            return cells[row][col].neighborMines > 0
        }
        
        for a in numbered {
            for b in numbered where a != b {
                let rowA = a / cols
                let colA = a % cols
                let rowB = b / cols
                let colB = b % cols
                
                let neighborsA = Set(neighborCache[a].filter { !revealed.contains($0) && !flagged.contains($0) })
                let neighborsB = Set(neighborCache[b].filter { !revealed.contains($0) && !flagged.contains($0) })
                
                guard !neighborsA.isEmpty, !neighborsB.isEmpty, neighborsA.isSubset(of: neighborsB), neighborsA != neighborsB else { continue }
                
                let flaggedA = neighborCache[a].filter { flagged.contains($0) }.count
                let flaggedB = neighborCache[b].filter { flagged.contains($0) }.count
                let remainingA = cells[rowA][colA].neighborMines - flaggedA
                let remainingB = cells[rowB][colB].neighborMines - flaggedB
                let diffSet = neighborsB.subtracting(neighborsA)
                let diffMines = remainingB - remainingA
                
                if diffMines == 0 {
                    for index in diffSet where !minePositions.contains(index) {
                        if revealVirtualCell(index, revealed: &revealed) {
                            return true
                        }
                    }
                } else if diffMines == diffSet.count {
                    for index in diffSet where !flagged.contains(index) {
                        flagged.insert(index)
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func applyLocalEnumerationRule(revealed: inout Set<Int>, flagged: inout Set<Int>) -> Bool {
        let numbered = Array(revealed).filter { idx in
            let row = idx / cols
            let col = idx % cols
            return cells[row][col].neighborMines > 0
        }
        
        for a in numbered {
            for b in numbered where a < b {
                let unknownA = Set(neighborCache[a].filter { !revealed.contains($0) && !flagged.contains($0) })
                let unknownB = Set(neighborCache[b].filter { !revealed.contains($0) && !flagged.contains($0) })
                let union = Array(unknownA.union(unknownB))
                
                guard !union.isEmpty, union.count <= 8 else { continue }
                guard !unknownA.isEmpty || !unknownB.isEmpty else { continue }
                
                let remainingA = remainingMineRequirement(for: a, flagged: flagged)
                let remainingB = remainingMineRequirement(for: b, flagged: flagged)
                guard remainingA >= 0, remainingB >= 0 else { continue }
                
                var validAssignments: [[Bool]] = []
                let totalMasks = 1 << union.count
                
                for mask in 0..<totalMasks {
                    let assignment = (0..<union.count).map { ((mask >> $0) & 1) == 1 }
                    if assignmentSatisfies(assignment, unknownSet: unknownA, union: union, requiredMines: remainingA) &&
                        assignmentSatisfies(assignment, unknownSet: unknownB, union: union, requiredMines: remainingB) {
                        validAssignments.append(assignment)
                    }
                }
                
                guard !validAssignments.isEmpty else { continue }
                
                for (idx, cellIndex) in union.enumerated() {
                    let allMine = validAssignments.allSatisfy { $0[idx] }
                    let allSafe = validAssignments.allSatisfy { !$0[idx] }
                    
                    if allMine && !flagged.contains(cellIndex) {
                        flagged.insert(cellIndex)
                        return true
                    }
                    if allSafe && !minePositions.contains(cellIndex) {
                        if revealVirtualCell(cellIndex, revealed: &revealed) {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private func remainingMineRequirement(for index: Int, flagged: Set<Int>) -> Int {
        let row = index / cols
        let col = index % cols
        let flaggedCount = neighborCache[index].filter { flagged.contains($0) }.count
        return cells[row][col].neighborMines - flaggedCount
    }
    
    private func assignmentSatisfies(_ assignment: [Bool], unknownSet: Set<Int>, union: [Int], requiredMines: Int) -> Bool {
        var count = 0
        for (idx, cellIndex) in union.enumerated() {
            if unknownSet.contains(cellIndex) && assignment[idx] {
                count += 1
            }
        }
        return count == requiredMines
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
