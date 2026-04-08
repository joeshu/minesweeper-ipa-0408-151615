// Last updated: 2026-04-08 16:59 CST
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
        board = (0..<rows).map { r in
            (0..<cols).map { c in Cell(row: r, col: c) }
        }
        placeMines(excluding: nil)
        calculateAdjacents()
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, !self.gameOver else { return }
            self.elapsedSeconds += 1
        }
    }

    private func placeMines(excluding safeSpot: (Int, Int)?) {
        for r in 0..<rows {
            for c in 0..<cols {
                board[r][c].isMine = false
                board[r][c].adjacent = 0
                board[r][c].isRevealed = false
                board[r][c].isFlagged = false
            }
        }
        var placed = 0
        while placed < mines {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            if let safeSpot, safeSpot.0 == r && safeSpot.1 == c { continue }
            if !board[r][c].isMine {
                board[r][c].isMine = true
                placed += 1
            }
        }
    }

    private func calculateAdjacents() {
        for r in 0..<rows {
            for c in 0..<cols {
                guard !board[r][c].isMine else { continue }
                board[r][c].adjacent = neighbors(ofRow: r, col: c).filter { board[$0.0][$0.1].isMine }.count
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
        objectWillChange.send()
    }

    func reveal(row: Int, col: Int) {
        guard !gameOver else { return }
        guard !board[row][col].isRevealed, !board[row][col].isFlagged else { return }

        if !firstMoveMade {
            firstMoveMade = true
            placeMines(excluding: (row, col))
            calculateAdjacents()
            startTimerIfNeeded()
        }

        board[row][col].isRevealed = true
        if board[row][col].isMine {
            gameOver = true
            didWin = false
            timer?.invalidate()
            revealAllMines()
            objectWillChange.send()
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
        objectWillChange.send()
    }

    private func floodReveal(row: Int, col: Int) {
        for (nr, nc) in neighbors(ofRow: row, col: col) {
            if !board[nr][nc].isRevealed && !board[nr][nc].isMine && !board[nr][nc].isFlagged {
                board[nr][nc].isRevealed = true
                if board[nr][nc].adjacent == 0 {
                    floodReveal(row: nr, col: nc)
                }
            }
        }
    }

    private func revealAllMines() {
        for r in 0..<rows {
            for c in 0..<cols where board[r][c].isMine {
                board[r][c].isRevealed = true
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

    var remainingMinesEstimate: Int {
        let flags = board.flatMap { $0 }.filter { $0.isFlagged }.count
        return max(0, mines - flags)
    }

    var boardWidth: Double {
        let size = cellSize
        let spacing = 4.0
        return Double(cols) * size + Double(max(0, cols - 1)) * spacing
    }

    var cellSize: Double {
        switch difficulty {
        case .beginner: return 34
        case .intermediate: return 20
        case .expert: return 18
        }
    }
}
