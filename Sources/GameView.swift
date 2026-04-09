import SwiftUI

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingNewGameConfirmation = false
    @State private var showingLoadGameConfirmation = false
    @State private var boardScale: CGFloat = 1.0
    @State private var boardOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                backgroundGradient
                
                VStack(spacing: 0) {
                    // 游戏信息栏
                    gameInfoBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // 快捷操作栏
                    quickActionBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if !viewModel.hintMessage.isEmpty {
                        hintBanner
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // 游戏板
                    gameBoardView
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    
                    // 控制按钮
                    controlButtons
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // 暂停覆盖层
                if viewModel.showPauseOverlay {
                    pauseOverlay
                }
                
                // 动画效果层
                ExplosionEffectView()
                ConfettiEffectView()
            }
            .navigationTitle("扫雷")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel.isGameActive {
                            showingNewGameConfirmation = true
                        } else {
                            viewModel.newGame()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                }
            }
            .alert("确认新游戏", isPresented: $showingNewGameConfirmation) {
                Button("取消", role: .cancel) { }
                Button("开始新游戏", role: .destructive) {
                    viewModel.newGame()
                }
            } message: {
                Text("当前游戏进度将丢失，确定要开始新游戏吗？")
            }
            .alert("游戏结束！", isPresented: $viewModel.showGameOverAlert) {
                Button("再玩一次") {
                    viewModel.newGame()
                }
            } message: {
                Text("你踩到地雷了！游戏结束。\n用时: \(viewModel.formattedTime)")
            }
            .alert("恭喜你赢了！", isPresented: $viewModel.showWinAlert) {
                Button("再玩一次") {
                    viewModel.newGame()
                }
            } message: {
                Text("你成功排除了所有地雷！\n用时: \(viewModel.formattedTime)")
            }
            .onAppear {
                if viewModel.hasSavedGame && !viewModel.isGameActive {
                    showingLoadGameConfirmation = true
                }
            }
            .alert("恢复游戏", isPresented: $showingLoadGameConfirmation) {
                Button("新游戏") {
                    viewModel.clearSavedGame()
                }
                Button("恢复进度") {
                    _ = viewModel.loadSavedGame()
                }
            } message: {
                Text("检测到有未完成的游戏，是否恢复进度？")
            }
        }
        .preferredColorScheme(themeManager.appTheme.colorScheme)
    }
    
    // MARK: - 背景渐变
    private var backgroundGradient: some View {
        Group {
            if themeManager.useGradientBackground {
                LinearGradient(
                    colors: [
                        themeManager.gameTheme.boardBackgroundColor.opacity(0.3),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - 游戏信息栏
    private var gameInfoBar: some View {
        HStack(spacing: 12) {
            // 剩余地雷数
            infoCard(
                icon: "flag.fill",
                iconColor: .red,
                value: "\(viewModel.remainingMines)",
                label: "地雷"
            )
            
            // 难度显示
            VStack(spacing: 2) {
                Text(viewModel.challengeMode == .none ? viewModel.difficulty.rawValue : viewModel.challengeMode.badgeTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("\(viewModel.gameBoard.rows)×\(viewModel.gameBoard.cols)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
            
            // 计时器
            infoCard(
                icon: viewModel.challengeMode == .timed ? "timer" : "clock",
                iconColor: viewModel.challengeMode == .timed ? .orange : .blue,
                value: viewModel.challengeMode == .timed ? "\(viewModel.challengeSecondsRemaining)s" : viewModel.formattedTime,
                label: viewModel.challengeMode == .timed ? "倒计时" : "时间"
            )
        }
    }
    
    private func infoCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - 快捷操作栏
    private var quickActionBar: some View {
        HStack(spacing: 12) {
            // 撤销按钮
            QuickActionButton(
                icon: "arrow.uturn.backward",
                label: "撤销",
                isEnabled: viewModel.canUndo && viewModel.gameBoard.gameState == .playing && !viewModel.isPaused
            ) {
                viewModel.undo()
            }
            
            // 暂停/继续按钮
            QuickActionButton(
                icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                label: viewModel.isPaused ? "继续" : "暂停",
                isEnabled: viewModel.isGameActive && viewModel.gameBoard.gameState == .playing,
                color: viewModel.isPaused ? .green : .orange
            ) {
                viewModel.togglePause()
            }
            
            // 提示按钮
            QuickActionButton(
                icon: "lightbulb.fill",
                label: "提示",
                isEnabled: viewModel.gameBoard.gameState == .playing && !viewModel.isPaused
            ) {
                viewModel.showHint()
            }
        }
    }
    
    private var hintBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: hintIcon)
                .foregroundColor(hintColor)
            Text(viewModel.hintMessage)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(hintColor.opacity(0.45), lineWidth: 1)
                )
        )
    }
    
    private var hintColor: Color {
        switch viewModel.hintKind {
        case .safe: return .green
        case .risky: return .orange
        case .none: return .secondary
        }
    }
    
    private var hintIcon: String {
        switch viewModel.hintKind {
        case .safe: return "checkmark.seal.fill"
        case .risky: return "exclamationmark.triangle.fill"
        case .none: return "lightbulb.max.fill"
        }
    }
    
    // MARK: - 游戏板视图
    private var gameBoardView: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            
            // 计算最佳单元格大小
            let cols = CGFloat(viewModel.gameBoard.cols)
            let rows = CGFloat(viewModel.gameBoard.rows)
            
            // 考虑间距后的可用空间
            let spacing: CGFloat = 2
            let totalSpacingX = (cols - 1) * spacing
            let totalSpacingY = (rows - 1) * spacing
            
            let cellWidth = (availableWidth - totalSpacingX) / cols
            let cellHeight = (availableHeight - totalSpacingY) / rows
            let cellSize = min(cellWidth, cellHeight, 55) // 最大55pt
            
            // 计算实际板尺寸
            let boardWidth = cols * cellSize + totalSpacingX
            let boardHeight = rows * cellSize + totalSpacingY
            
            // 居中偏移
            let offsetX = (availableWidth - boardWidth) / 2
            let offsetY = (availableHeight - boardHeight) / 2
            
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                LazyVStack(spacing: spacing) {
                    ForEach(0..<viewModel.gameBoard.rows, id: \.self) { row in
                        LazyHStack(spacing: spacing) {
                            ForEach(0..<viewModel.gameBoard.cols, id: \.self) { col in
                                let cell = viewModel.gameBoard.cells[row][col]
                                let isHint = viewModel.isShowingHint && 
                                            viewModel.hintPosition?.row == row && 
                                            viewModel.hintPosition?.col == col
                                
                                CellView(
                                    cell: cell,
                                    cellSize: cellSize,
                                    isHint: isHint,
                                    onTap: {
                                        viewModel.revealCell(row: row, col: col)
                                    },
                                    onLongPress: {
                                        viewModel.toggleFlag(row: row, col: col)
                                    },
                                    onDoubleTap: {
                                        viewModel.quickReveal(row: row, col: col)
                                    }
                                )
                                .id("\(row)-\(col)")
                            }
                        }
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.gameTheme.boardBackgroundColor)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, max(0, offsetX))
                .padding(.vertical, max(0, offsetY))
            }
        }
    }
    
    // MARK: - 暂停覆盖层
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("游戏暂停")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("用时: \(viewModel.formattedTime)")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    viewModel.resumeGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("继续游戏")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.newGame()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("新游戏")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - 快捷操作按钮
struct QuickActionButton: View {
    let icon: String
    let label: String
    var isEnabled: Bool = true
    var color: Color = .blue
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isEnabled ? color.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .foregroundColor(isEnabled ? color : .gray)
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.1) : nil, value: isEnabled)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
            .environmentObject(GameViewModel())
            .environmentObject(ThemeManager.shared)
    }
}
