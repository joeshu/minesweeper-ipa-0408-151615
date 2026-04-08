// Last updated: 2026-04-08 18:23 CST
import SwiftUI

struct ContentView: View {
    @StateObject private var game = MinesweeperGame()
    @State private var showingResultAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.10), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    VStack(spacing: 14) {
                        Picker("难度", selection: difficultyBinding) {
                            ForEach(Difficulty.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            StatusBadge(systemImage: "flag.fill", text: "\(game.remainingMinesEstimate)", color: .orange)
                            Spacer()
                            StatusBadge(systemImage: "timer", text: "\(game.elapsedSeconds)s", color: .blue)
                            Spacer()
                            Button {
                                Haptics.tap()
                                game.reset()
                            } label: {
                                Label("重开", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }

                        HStack(spacing: 10) {
                            Text(statusText)
                                .font(.headline)
                                .foregroundStyle(statusColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if let best = BestScoreStore.bestTime(for: game.difficulty) {
                                StatusBadge(systemImage: "trophy.fill", text: "最佳 \(best)s", color: .green)
                            }
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 18, y: 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        BoardView(game: game)
                            .frame(width: game.boardWidth)
                            .padding(10)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .blue.opacity(0.10), radius: 16, y: 8)
                            .padding(.horizontal, 2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("iPhone 风格扫雷", systemImage: "sparkles")
                            .font(.subheadline.bold())
                        Text("点按翻开格子，长按插旗。首点会保护周围九宫格，更容易展开。现在会按难度记录最佳通关时间。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle("扫雷")
            .onChange(of: game.gameOver) { newValue in
                if newValue {
                    if game.didWin {
                        BestScoreStore.registerWin(seconds: game.elapsedSeconds, difficulty: game.difficulty)
                        Haptics.success()
                    } else {
                        Haptics.error()
                    }
                    showingResultAlert = true
                }
            }
            .alert(game.didWin ? "你赢了" : "踩雷了", isPresented: $showingResultAlert) {
                Button("再来一局") {
                    Haptics.tap()
                    game.reset()
                }
                Button("关闭", role: .cancel) {}
            } message: {
                if game.didWin, let best = BestScoreStore.bestTime(for: game.difficulty) {
                    Text("用时 \(game.elapsedSeconds) 秒。当前难度最佳成绩：\(best) 秒。")
                } else {
                    Text("这次有误旗提示，方便你复盘。")
                }
            }
        }
    }

    private var difficultyBinding: Binding<Difficulty> {
        Binding(
            get: { game.difficulty },
            set: {
                Haptics.tap()
                game.applyDifficulty($0)
            }
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

struct StatusBadge: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
                .monospacedDigit()
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: Capsule())
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
                                Haptics.tap()
                                game.reveal(row: r, col: c)
                            }
                            .onLongPressGesture(minimumDuration: 0.35) {
                                Haptics.tap()
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
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
                .frame(width: size, height: size)
                .shadow(color: cell.isRevealed ? .clear : .white.opacity(0.5), radius: 1, x: 0, y: -1)

            if cell.wrongFlag {
                Image(systemName: "xmark")
                    .font(.system(size: max(9, size * 0.38), weight: .bold))
                    .foregroundStyle(.red)
            } else if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: cell.didExplode ? "flame.fill" : "burst.fill")
                        .font(.system(size: max(10, size * 0.5)))
                        .foregroundStyle(cell.didExplode ? .red : .primary)
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
        .scaleEffect(cell.didExplode ? 1.03 : 1.0)
    }

    private var backgroundFill: some ShapeStyle {
        if cell.wrongFlag { return AnyShapeStyle(Color.red.opacity(0.12)) }
        if cell.isRevealed {
            return AnyShapeStyle(cell.isMine ? Color.red.opacity(0.18) : Color.gray.opacity(0.18))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [Color.white.opacity(0.95), Color.blue.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var borderColor: Color {
        if cell.didExplode { return .red.opacity(0.65) }
        return cell.isRevealed ? .gray.opacity(0.2) : .blue.opacity(0.18)
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
