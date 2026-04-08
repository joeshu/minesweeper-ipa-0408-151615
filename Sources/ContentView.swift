// Last updated: 2026-04-08 15:24 CST
import SwiftUI

struct ContentView: View {
    @StateObject private var game = MinesweeperGame()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Label("\(game.remainingMinesEstimate)", systemImage: "flag.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Button {
                        game.reset()
                    } label: {
                        Label("重开", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text(statusText)
                    .font(.headline)
                    .foregroundStyle(statusColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                BoardView(game: game)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 6) {
                    Text("玩法")
                        .font(.subheadline.bold())
                    Text("点按翻开格子，长按插旗。翻到雷就失败，翻完所有非雷格子即获胜。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .navigationTitle("扫雷")
        }
    }

    private var statusText: String {
        if game.gameOver { return game.didWin ? "你赢了！" : "踩雷了，再来一局" }
        return "进行中"
    }

    private var statusColor: Color {
        if game.gameOver { return game.didWin ? .green : .red }
        return .blue
    }
}

struct BoardView: View {
    @ObservedObject var game: MinesweeperGame

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<game.rows, id: \.self) { r in
                HStack(spacing: 4) {
                    ForEach(0..<game.cols, id: \.self) { c in
                        let cell = game.board[r][c]
                        CellView(cell: cell)
                            .onTapGesture {
                                game.reveal(row: r, col: c)
                            }
                            .onLongPressGesture {
                                game.toggleFlag(row: r, col: c)
                            }
                    }
                }
            }
        }
    }
}

struct CellView: View {
    let cell: Cell

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: 34, height: 34)
            if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: "burst.fill")
                        .foregroundStyle(.red)
                } else if cell.adjacent > 0 {
                    Text("\(cell.adjacent)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(numberColor)
                }
            } else if cell.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    private var backgroundColor: Color {
        if cell.isRevealed { return cell.isMine ? .red.opacity(0.18) : .gray.opacity(0.18) }
        return .blue.opacity(0.16)
    }

    private var numberColor: Color {
        switch cell.adjacent {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return .purple
        default: return .primary
        }
    }
}
