// Last updated: 2026-04-09 12:35 CST - 优化性能
import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case beginner = "初级"
    case intermediate = "中级"
    case expert = "高级"

    var id: String { rawValue }

    var config: (rows: Int, cols: Int, mines: Int) {
        switch self {
        case .beginner: return (9, 9, 10)
        case .intermediate: return (16, 16, 40)
        case .expert: return (16, 16, 60)
        }
    }
}

struct Cell: Identifiable {
    let id = UUID()
    var row: Int
    var col: Int
    var isMine: Bool = false
    var adjacent: Int = 0
    var isRevealed: Bool = false
    var isFlagged: Bool = false
    var didExplode: Bool = false
    var wrongFlag: Bool = false
}

final class MinesweeperGame: ObservableObject {
    @Published var board: [[Cell]] = []
    @Published var gameOver = false
    @Published var didWin = false
    @Published var elapsedSeconds = 0
    @Published var difficulty: Difficulty = .beginner

    private(set) var rows: Int = 9
    private(set) var cols: Int = 9
    private(set) var mines: Int = 10

    private var firstMoveMade = false
    private var timer: Timer?
    private var needsUpdate = false

    init() {
        applyDifficulty(.beginner)
    }

    deinit {
        timer?.invalidate()
    }

    func applyDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        let cfg = newDifficulty.config
        rows = cfg.rows
        cols = cfg.cols
        mines = cfg.mines
        reset()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        gameOver = false
        didWin = false
        firstMoveMade = false
        needsUpdate = false
        
        // 优化：批量创建棋盘，减少发布次数
        let newBoard = (0..<rows).map { r in
            (0..<cols).map { c in Cell(row: r, col: c) }
        }
        board = newBoard
        placeMines(excludingZone: nil)
        calculateAdjacents()
        objectWillChange.send()
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, !self.gameOver else { 
                self.timer?.invalidate()
                self.timer = nil
                return 
            }
            self.elapsedSeconds += 1
        }
    }

    private func protectedZone(row: Int, col: Int) -> Set<String> {
        var zone: Set<String> = []
        for r in max(0, row - 1)...min(rows - 1, row + 1) {
            for c in max(0, col - 1)...min(cols - 1, col + 1) {
                zone.insert("\(r)-\(c)")
            }
        }
        return zone
    }

    private func placeMines(excludingZone safeZone: Set<String>?) {
        // 优化：重用现有数组而不是重新创建
        for r in 0..<rows {
            for c in 0..<cols {
                board[r][c].isMine = false
                board[r][c].adjacent = 0
                board[r][c].isRevealed = false
                board[r][c].isFlagged = false
                board[r][c].didExplode = false
                board[r][c].wrongFlag = false
            }
        }
        
        var placed = 0
        let maxAttempts = mines * 10 // 防止无限循环
        var attempts = 0
        
        while placed < mines && attempts < maxAttempts {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            attempts += 1
            
            if let safeZone, safeZone.contains("\(r)-\(c)") { continue }
            if !board[r][c].isMine {
                board[r][c].isMine = true
                placed += 1
            }
        }
    }

    private func calculateAdjacents() {
        // 优化：减少重复计算
        for r in 0..<rows {
            for c in 0..<cols {
                guard !board[r][c].isMine else { continue }
                board[r][c].adjacent = neighbors(ofRow: r, col: c).reduce(0) { count, neighbor in
                    count + (board[neighbor.0][neighbor.1].isMine ? 1 : 0)
                }
            }
        }
    }

    private func neighbors(ofRow row: Int, col: Int) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for r in max(0, row - 1)...min(rows - 1, row + 1) {
            for c in max(0, col - 1)...min(cols - 1, col + 1) {
                if r == row && c == col { continue }
                result.append((r, c))
            }
        }
        return result
    }

    func toggleFlag(row: Int, col: Int) {
        guard !gameOver, !board[row][col].isRevealed else { return }
        board[row][col].isFlagged.toggle()
        scheduleUpdate()
    }

    func reveal(row: Int, col: Int) {
        guard !gameOver else { return }
        guard !board[row][col].isRevealed, !board[row][col].isFlagged else { return }

        if !firstMoveMade {
            firstMoveMade = true
            placeMines(excludingZone: protectedZone(row: row, col: col))
            calculateAdjacents()
            startTimerIfNeeded()
        }

        board[row][col].isRevealed = true
        if board[row][col].isMine {
            gameOver = true
            didWin = false
            board[row][col].didExplode = true
            timer?.invalidate()
            revealAllMinesAndWrongFlags()
            scheduleUpdate()
            return
        }

        if board[row][col].adjacent == 0 {
            floodReveal(row: row, col: col)
        }

        if checkWin() {
            gameOver = true
            didWin = true
            timer?.invalidate()
            autoFlagRemainingMines()
        }
        scheduleUpdate()
    }

    // 优化：使用迭代而非递归，防止堆栈溢出
    private func floodReveal(row: Int, col: Int) {
        var queue: [(Int, Int)] = [(row, col)]
        var visited: Set<String> = [ "\(row)-\(col)" ]
        
        while !queue.isEmpty {
            let (currentRow, currentCol) = queue.removeFirst()
            
            for (nr, nc) in neighbors(ofRow: currentRow, col: currentCol) {
                let key = "\(nr)-\(nc)"
                
                if !visited.contains(key) && !board[nr][nc].isRevealed && !board[nr][nc].isMine && !board[nr][nc].isFlagged {
                    board[nr][nc].isRevealed = true
                    visited.insert(key)
                    
                    if board[nr][nc].adjacent == 0 {
                        queue.append((nr, nc))
                    }
                }
            }
        }
    }

    private func revealAllMinesAndWrongFlags() {
        for r in 0..<rows {
            for c in 0..<cols {
                if board[r][c].isMine {
                    board[r][c].isRevealed = true
                } else if board[r][c].isFlagged {
                    board[r][c].wrongFlag = true
                    board[r][c].isRevealed = true
                }
            }
        }
    }

    private func autoFlagRemainingMines() {
        for r in 0..<rows {
            for c in 0..<cols where board[r][c].isMine {
                board[r][c].isFlagged = true
            }
        }
    }

    private func checkWin() -> Bool {
        for r in 0..<rows {
            for c in 0..<cols {
                let cell = board[r][c]
                if !cell.isMine && !cell.isRevealed { return false }
            }
        }
        return true
    }

    // 优化：批量更新，减少UI刷新次数
    private func scheduleUpdate() {
        needsUpdate = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self, self.needsUpdate else { return }
            self.needsUpdate = false
            self.objectWillChange.send()
        }
    }

    var remainingMinesEstimate: Int {
        let flags = board.flatMap { $0 }.filter { $0.isFlagged }.count
        return mines - flags
    }

    var boardWidth: Double {
        let size = cellSize
        let spacing = 4.0
        return Double(cols) * size + Double(max(0, cols - 1)) * spacing
    }

    var cellSize: Double {
        switch difficulty {
        case .beginner: return 34
        case .intermediate: return 22  // 稍微增大一点，更容易点击
        case .expert: return 20       // 稍微增大一点，更容易点击
        }
    }
}