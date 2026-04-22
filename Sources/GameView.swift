import SwiftUI

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingNewGameConfirmation = false
    @State private var showingLoadGameConfirmation = false
    @State private var boardScale: CGFloat = 1.0
    @State private var boardOffset: CGSize = .zero
    
    private let boardHeaderReservedHeight: CGFloat = 4
    
    private var statusTitle: String {
        if viewModel.isPaused { return "已暂停" }
        switch viewModel.gameBoard.gameState {
        case .playing:
            return viewModel.isGameActive ? "进行中" : "准备开始"
        case .won:
            return "挑战成功"
        case .lost:
            return "本局失败"
        }
    }
    
    private var statusSubtitle: String {
        switch viewModel.challengeMode {
        case .none:
            return "专注当前棋盘，保持节奏。"
        case .daily:
            return "今日挑战只算一次成绩。"
        case .timed:
            return "注意剩余时间，优先做确定操作。"
        case .noGuess:
            return "当前为无猜挑战，优先利用信息链。"
        }
    }
    
    private var statusColor: Color {
        if viewModel.isPaused { return .orange }
        switch viewModel.gameBoard.gameState {
        case .playing: return .green
        case .won: return .yellow
        case .lost: return .red
        }
    }
    
    private var progressText: String {
        let totalSafeCells = max(1, viewModel.gameBoard.rows * viewModel.gameBoard.cols - viewModel.gameBoard.totalMines)
        let progress = Double(viewModel.gameBoard.revealedCount) / Double(totalSafeCells)
        return String(format: "已推进 %.0f%%", progress * 100)
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    GameTopStatusBar(
                        statusTitle: statusTitle,
                        statusSubtitle: statusSubtitle,
                        statusColor: statusColor,
                        progressText: progressText,
                        modeBadgeColor: modeBadgeColor
                    )
                    .environmentObject(viewModel)
                    .padding(.horizontal, 8)
                    .padding(.top, 1)
                    
                    GameBottomControlPanel(showingNewGameConfirmation: $showingNewGameConfirmation)
                        .environmentObject(viewModel)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                    
                    if !viewModel.gameBoard.generationQualityNote.isEmpty && viewModel.challengeMode == .noGuess {
                        generationBanner
                            .padding(.horizontal, 8)
                            .padding(.bottom, 2)
                    }
                }
                
                GameBoardContainer(boardHeaderReservedHeight: boardHeaderReservedHeight)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 2)
                    .padding(.top, 1)
                    .padding(.bottom, 3)
            }
            
            // 暂停覆盖层
            if viewModel.showPauseOverlay {
                pauseOverlay
            }
            
            if viewModel.showGameOverAlert || viewModel.showWinAlert {
                resultOverlay
            }
            
            if let latestAchievement = viewModel.newlyUnlockedAchievements.last {
                VStack {
                    achievementToast(achievement: latestAchievement)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.22) : nil, value: latestAchievement.id)
            }
            
            if !viewModel.hintMessage.isEmpty {
                VStack {
                    Spacer(minLength: 0)
                    hintBanner
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.18) : nil, value: viewModel.hintMessage)
            }
            
            if !viewModel.boardStatusMessage.isEmpty && !viewModel.showGameOverAlert && !viewModel.showWinAlert {
                VStack {
                    Spacer(minLength: 0)
                    boardStatusBanner
                        .padding(.horizontal, 14)
                        .padding(.bottom, viewModel.hintMessage.isEmpty ? 12 : 70)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.16) : nil, value: viewModel.boardStatusMessage)
            }
            
            if let assessment = viewModel.tacticalAssessment, (viewModel.showGameOverAlert || viewModel.showWinAlert) {
                VStack {
                    Spacer(minLength: 0)
                    tacticalAssessmentBanner(assessment)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 24)
                }
            }
            
            // 动画效果层
            ExplosionEffectView()
            ConfettiEffectView()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(themeManager.appTheme.colorScheme)
        .onAppear {
            if viewModel.hasSavedGame && !viewModel.isGameActive {
                showingLoadGameConfirmation = true
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
    
    // MARK: - 页面骨架
    private var backgroundGradient: some View {
        Group {
            if themeManager.useGradientBackground {
                if themeManager.gameTheme == .cyber {
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.05, blue: 0.12),
                            Color(red: 0.05, green: 0.10, blue: 0.20),
                            Color(.systemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [
                            themeManager.gameTheme.boardBackgroundColor.opacity(0.3),
                            Color(.systemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var modeBadgeColor: Color {
        switch viewModel.challengeMode {
        case .none: return .blue
        case .daily: return .purple
        case .timed: return .orange
        case .noGuess: return .green
        }
    }
    
    private var generationBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.gameBoard.generationQualityNote.contains("严格") ? "shield.checkered" : "wand.and.stars")
                .foregroundColor(viewModel.gameBoard.generationQualityNote.contains("严格") ? .green : .orange)
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text("盘面质量")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(viewModel.gameBoard.generationQualityNote)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(12)
        .surfaceCard(radius: 16, fillColor: Color(.secondarySystemBackground).opacity(0.88), shadowOpacity: 0.04)
    }
    
    private var hintBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(hintColor.opacity(0.18))
                    .frame(width: 30, height: 30)
                Image(systemName: hintIcon)
                    .foregroundColor(hintColor)
                    .font(.footnote.weight(.bold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(hintTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(hintColor)
                Text(viewModel.hintMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(hintColor.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: hintColor.opacity(0.08), radius: 6, x: 0, y: 2)
        )
    }
    
    private var boardStatusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(boardStatusColor.opacity(0.18))
                .frame(width: 18, height: 18)
                .overlay(
                    Image(systemName: boardStatusIcon)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(boardStatusColor)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.boardStatusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                if !viewModel.boardStatusDetail.isEmpty {
                    Text(viewModel.boardStatusDetail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(boardStatusColor.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func tacticalAssessmentBanner(_ assessment: TacticalAssessment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("任务评估 · \(assessment.grade)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(colorFromHex(assessment.gradeColorHex))
                Spacer(minLength: 0)
                Text(assessment.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            Text(assessment.signature)
                .font(.caption2.monospaced())
                .foregroundColor(colorFromHex(assessment.gradeColorHex).opacity(0.92))
            Text(assessment.detail)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(colorFromHex(assessment.gradeColorHex).opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func colorFromHex(_ hex: String) -> Color {
        switch hex {
        case "#47F5FF": return Color.cyan
        case "#7CFF8E": return Color.green
        case "#FFD25E": return Color.orange
        case "#FF9B5E": return Color.orange.opacity(0.9)
        case "#FF5E7A": return Color.red
        default: return .blue
        }
    }

        switch viewModel.boardStatusTone {
        case .neutral: return .blue
        case .positive: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }
    
    private var boardStatusIcon: String {
        switch viewModel.boardStatusTone {
        case .neutral: return "circle.fill"
        case .positive: return "checkmark"
        case .warning: return "flag.fill"
        case .danger: return "xmark"
        }
    }

    private var hintTitle: String {
        switch viewModel.hintKind {
        case .safe: return "安全提示"
        case .flag: return "标雷提示"
        case .risky: return "风险提示"
        case .none: return "提示"
        }
    }

    private var hintColor: Color {
        switch viewModel.hintKind {
        case .safe: return .green
        case .flag: return .red
        case .risky: return .orange
        case .none: return .secondary
        }
    }
    
    private var hintIcon: String {
        switch viewModel.hintKind {
        case .safe: return "checkmark.seal.fill"
        case .flag: return "flag.fill"
        case .risky: return "exclamationmark.triangle.fill"
        case .none: return "lightbulb.max.fill"
        }
    }
    
    // MARK: - 暂停覆盖层
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                
                Text("游戏暂停")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                
                Text("当前用时 \(viewModel.formattedTime)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.82))
                
                Text("休息一下，准备好后继续推进这一局。")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.72))
                
                Button(action: {
                    viewModel.resumeGame()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("继续游戏")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.green)
                    )
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.18))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
        }
    }
    
    // MARK: - 控制按钮
    private var controlButtons: some View {
        HStack {
            Spacer()
            Button(action: {
                if viewModel.isGameActive {
                    showingNewGameConfirmation = true
                } else {
                    viewModel.newGame()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("新游戏")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.28), radius: 8, x: 0, y: 4)
            }
            Spacer()
        }
    }

    private func achievementToast(achievement: Achievement) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: achievement.icon)
                    .foregroundColor(.yellow)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("成就解锁")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.yellow)
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                Text(achievement.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill((viewModel.showWinAlert ? Color.yellow : Color.red).opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: viewModel.showWinAlert ? "trophy.fill" : "xmark.octagon.fill")
                        .font(.system(size: 34))
                        .foregroundColor(viewModel.showWinAlert ? .yellow : .red)
                }

                VStack(spacing: 6) {
                    Text(viewModel.showWinAlert ? "本局胜利" : "本局失败")
                        .font(.title2.weight(.bold))
                    Text(viewModel.showWinAlert ? "节奏很好，继续保持。" : "别急，下一局很快就能追回来。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    resultRow(title: "模式", value: viewModel.challengeMode.rawValue)
                    resultRow(title: "难度", value: viewModel.difficulty.rawValue)
                    resultRow(title: "用时", value: viewModel.formattedTime)
                    resultRow(title: "已翻开", value: "\(viewModel.gameBoard.revealedCount) 格")
                    resultRow(title: "已标记", value: "\(viewModel.gameBoard.flaggedCount)/\(viewModel.gameBoard.totalMines)")
                    if viewModel.challengeMode == .noGuess && !viewModel.gameBoard.generationQualityNote.isEmpty {
                        resultRow(title: "盘面质量", value: viewModel.gameBoard.generationQualityNote)
                    }
                }
                .padding(14)
                .surfaceCard(radius: 16, fillColor: Color(.secondarySystemBackground).opacity(0.72), shadowOpacity: 0)

                HStack(spacing: 12) {
                    Button {
                        viewModel.showGameOverAlert = false
                        viewModel.showWinAlert = false
                    } label: {
                        Text("关闭")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    Button {
                        viewModel.showGameOverAlert = false
                        viewModel.showWinAlert = false
                        viewModel.newGame()
                    } label: {
                        Text("再来一局")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.blue)
                            )
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: 332)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
        }
    }

    private func resultRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
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
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? color.opacity(0.12) : Color.gray.opacity(0.07))
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
