import Foundation

enum CellState: Equatable, Hashable {
    case hidden
    case revealed
    case flagged
    case questioned
    case exploded
}

struct Cell: Identifiable, Equatable, Hashable {
    let id: UUID
    let row: Int
    let col: Int
    let isMine: Bool
    let neighborMines: Int
    var state: CellState
    
    init(row: Int, col: Int, isMine: Bool = false, neighborMines: Int = 0, state: CellState = .hidden) {
        self.id = UUID()
        self.row = row
        self.col = col
        self.isMine = isMine
        self.neighborMines = neighborMines
        self.state = state
    }
    
    // Equatable: 只比较关键属性，忽略id
    static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.row == rhs.row &&
        lhs.col == rhs.col &&
        lhs.isMine == rhs.isMine &&
        lhs.neighborMines == rhs.neighborMines &&
        lhs.state == rhs.state
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(col)
    }
    
    var displayText: String {
        switch state {
        case .hidden:
            return ""
        case .flagged:
            return "🚩"
        case .questioned:
            return "❓"
        case .exploded:
            return "💥"
        case .revealed:
            if isMine {
                return "💣"
            } else if neighborMines > 0 {
                return String(neighborMines)
            } else {
                return ""
            }
        }
    }
    
    var displayColor: String {
        switch state {
        case .revealed where !isMine && neighborMines > 0:
            switch neighborMines {
            case 1: return "blue"
            case 2: return "green"
            case 3: return "red"
            case 4: return "purple"
            case 5: return "maroon"
            case 6: return "turquoise"
            case 7: return "black"
            case 8: return "gray"
            default: return "black"
            }
        default:
            return "black"
        }
    }
    
    var isRevealed: Bool {
        if case .revealed = state { return true }
        return false
    }
    
    var isHidden: Bool {
        if case .hidden = state { return true }
        return false
    }
    
    var isFlagged: Bool {
        if case .flagged = state { return true }
        return false
    }
}
