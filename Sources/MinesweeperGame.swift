// Last updated: 2026-04-08 15:16 CST
import Foundation

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

    let rows: Int
    let cols: Int
    let mines: Int

    init(rows: Int = 9, cols: Int = 9, mines: Int = 10) {
        self.rows = rows
        self.cols = cols
        self.mines = mines
        reset()
    }

    func reset() {
        gameOver = false
        didWin = false
        board = (0..<rows).map { r in
            (0..<cols).map { c in Cell(row: r, col: c) }
        }
        placeMines()
        calculateAdjacents()
    }

    private func placeMines() {
        var placed = 0
        while placed < mines {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
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

        board[row][col].isRevealed = true
        if board[row][col].isMine {
            gameOver = true
            didWin = false
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
}
