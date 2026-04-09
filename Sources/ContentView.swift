// Last updated: 2026-04-09 12:35 CST - 优化界面显示和性能
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var game = MinesweeperGame()
    @State private var showingResultAlert = false
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // 顶部控制区域
                    VStack(spacing: 12) {
                        HStack {
                            Picker("难度", selection: difficultyBinding) {
                                ForEach(Difficulty.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 200)
                            
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

                        HStack(spacing: 12) {
                            StatusBadge(systemImage: "flag.fill", text: "\(game.remainingMinesEstimate)", color: .orange)
                            StatusBadge(systemImage: "timer", text: "\(game.elapsedSeconds)s", color: .blue)
                            if let best = BestScoreStore.bestTime(for: game.difficulty) {
                                StatusBadge(systemImage: "trophy.fill", text: "最佳 \(best)s", color: .green)
                            }
                        }
                    }
                    .padding(16)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 12, y: 6)

                    // 游戏棋盘区域 - 优化布局
                    GeometryReader { geometry in
                        let boardWidth = min(game.boardWidth, geometry.size.width - 40)
                        let cellSize = boardWidth / Double(game.cols)
                        
                        BoardView(game: game, cellSize: cellSize)
                            .frame(width: boardWidth, height: cellSize * Double(game.rows) + 4.0 * Double(max(0, game.rows - 1)))
                            .background(boardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .blue.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: 8, y: 4)
                            .padding(.horizontal, 20)
                            .onAppear {
                                containerWidth = geometry.size.width
                            }
                    }

                    // 底部信息区域
                    VStack(alignment: .leading, spacing: 6) {
                        Label("iPhone 风格扫雷", systemImage: "sparkles")
                            .font(.subheadline.bold())
                        Text("已加入深色模式适配、App 图标和最佳成绩记录。点按翻开格子，长按插旗。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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

    private var backgroundGradient: [Color] {
        if colorScheme == .dark {
            return [Color.black, Color.blue.opacity(0.3), Color.indigo.opacity(0.25)]
        }
        return [Color.blue.opacity(0.15), Color.cyan.opacity(0.08), Color.white]
    }

    private var cardBackground: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(.ultraThinMaterial)
    }

    private var boardBackground: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(.regularMaterial)
    }
}

struct StatusBadge: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
                .monospacedDigit()
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1), in: Capsule())
    }
}

// 优化性能的棋盘视图
struct BoardView: View {
    @ObservedObject var game: MinesweeperGame
    let cellSize: Double

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize + 4), spacing: 4), count: game.cols),
                  spacing: 4) {
            ForEach(0..<game.rows * game.cols, id: \.self) { index in
                let row = index / game.cols
                let col = index % game.cols
                let cell = game.board[row][col]
                
                CellView(cell: cell, size: cellSize)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.tap()
                        game.reveal(row: row, col: col)
                    }
                    .onLongPressGesture(minimumDuration: 0.3) {
                        Haptics.tap()
                        game.toggleFlag(row: row, col: col)
                    }
            }
        }
    }
}

// 优化性能的单元格视图
struct CellView: View {
    @Environment(\.colorScheme) private var colorScheme
    let cell: Cell
    let size: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: 0.5)
                )
                .frame(width: size, height: size)
                .shadow(color: cell.isRevealed ? .clear : .white.opacity(colorScheme == .dark ? 0.06 : 0.3), 
                       radius: cell.isRevealed ? 0 : 1, x: 0, y: -1)

            if cell.wrongFlag {
                Image(systemName: "xmark")
                    .font(.system(size: max(8, size * 0.35), weight: .bold))
                    .foregroundStyle(.red)
            } else if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: cell.didExplode ? "flame.fill" : "burst.fill")
                        .font(.system(size: max(9, size * 0.45)))
                        .foregroundStyle(cell.didExplode ? .red : .primary)
                } else if cell.adjacent > 0 {
                    Text("\(cell.adjacent)")
                        .font(.system(size: max(9, size * 0.4), weight: .bold, design: .rounded))
                        .foregroundStyle(numberColor)
                }
            } else if cell.isFlagged {
                Image(systemName: "flag.fill")
                    .font(.system(size: max(9, size * 0.4)))
                    .foregroundStyle(.orange)
            }
        }
        .scaleEffect(cell.didExplode ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: cell.didExplode)
    }

    private var backgroundFill: some ShapeStyle {
        if cell.wrongFlag { return AnyShapeStyle(Color.red.opacity(0.1)) }
        if cell.isRevealed {
            return AnyShapeStyle(cell.isMine ? Color.red.opacity(0.2) : Color.gray.opacity(colorScheme == .dark ? 0.25 : 0.15))
        }
        return AnyShapeStyle(
            colorScheme == .dark ? 
            Color.white.opacity(0.08) : 
            Color.white.opacity(0.9)
        )
    }

    private var borderColor: Color {
        if cell.didExplode { return .red.opacity(0.5) }
        return cell.isRevealed ? .gray.opacity(0.15) : .blue.opacity(colorScheme == .dark ? 0.2 : 0.12)
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