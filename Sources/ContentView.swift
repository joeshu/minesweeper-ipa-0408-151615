// Last updated: 2026-04-08 17:07 CST
import SwiftUI

struct ContentView: View {
    @StateObject private var game = MinesweeperGame()
    @State private var showingResultAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("难度", selection: difficultyBinding) {
                    ForEach(Difficulty.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Label("\(game.remainingMinesEstimate)", systemImage: "flag.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Label("\(game.elapsedSeconds)s", systemImage: "timer")
                        .foregroundStyle(.blue)
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

                ScrollView(.horizontal, showsIndicators: false) {
                    BoardView(game: game)
                        .frame(width: game.boardWidth)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("玩法")
                        .font(.subheadline.bold())
                    Text("点按翻开格子，长按插旗。首点保证不是雷。初级为 9×9，支持切换中级与高级。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .navigationTitle("扫雷")
            .onChange(of: game.gameOver) { newValue in
                if newValue {
                    showingResultAlert = true
                }
            }
            .alert(game.didWin ? "你赢了" : "踩雷了", isPresented: $showingResultAlert) {
                Button("再来一局") {
                    game.reset()
                }
                Button("关闭", role: .cancel) {}
            } message: {
                Text(game.didWin ? "用时 \(game.elapsedSeconds) 秒，已自动标出剩余地雷。" : "别灰心，下一局一定行。")
            }
        }
    }

    private var difficultyBinding: Binding<Difficulty> {
        Binding(
            get: { game.difficulty },
            set: { game.applyDifficulty($0) }
        )
    }

    private var statusText: String {
        if game.gameOver { return game.didWin ? "你赢了！" : "踩雷了，再来一局" }
        return "进行中 · \(game.difficulty.rawValue)"
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
                        CellView(cell: cell, size: game.cellSize)
                            .contentShape(Rectangle())
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
    let size: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: 1)
                )
                .frame(width: size, height: size)
            if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: "burst.fill")
                        .font(.system(size: max(10, size * 0.5)))
                        .foregroundStyle(.red)
                } else if cell.adjacent > 0 {
                    Text("\(cell.adjacent)")
                        .font(.system(size: max(10, size * 0.45), weight: .bold, design: .rounded))
                        .foregroundStyle(numberColor)
                }
            } else if cell.isFlagged {
                Image(systemName: "flag.fill")
                    .font(.system(size: max(10, size * 0.45)))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var backgroundColor: Color {
        if cell.isRevealed { return cell.isMine ? .red.opacity(0.18) : .gray.opacity(0.18) }
        return .blue.opacity(0.12)
    }

    private var borderColor: Color {
        cell.isRevealed ? .gray.opacity(0.2) : .blue.opacity(0.3)
    }

    private var numberColor: Color {
        switch cell.adjacent {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return .purple
        case 5: return .orange
        case 6: return .cyan
        default: return .primary
        }
    }
}
