import SwiftUI

struct GameTopStatusBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    let statusTitle: String
    let statusSubtitle: String
    let statusColor: Color
    let progressText: String
    let modeBadgeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(statusColor.opacity(0.18))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 5, height: 5)
                            )
                        Text(statusTitle)
                            .font(.subheadline.weight(.bold))
                    }
                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(progressText)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(statusColor)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 6) {
                    ModeBadge(
                        title: viewModel.challengeMode == .none ? viewModel.difficulty.rawValue : viewModel.challengeMode.badgeTitle,
                        color: modeBadgeColor
                    )
                    ModeBadge(
                        title: "\(viewModel.gameBoard.rows)×\(viewModel.gameBoard.cols)",
                        color: .secondary
                    )
                }
            }
            
            HStack(spacing: 10) {
                GameStatChip(
                    icon: "flag.fill",
                    iconColor: .red,
                    title: "剩余地雷",
                    value: "\(viewModel.remainingMines)"
                )
                
                GameStatChip(
                    icon: viewModel.challengeMode == .timed ? "timer" : "clock",
                    iconColor: viewModel.challengeMode == .timed ? .orange : .blue,
                    title: viewModel.challengeMode == .timed ? "剩余时间" : "当前用时",
                    value: viewModel.challengeMode == .timed ? "\(viewModel.challengeSecondsRemaining)s" : viewModel.formattedTime
                )
            }
            
            if viewModel.challengeMode == .noGuess && !viewModel.gameBoard.generationQualityNote.isEmpty {
                ModeBadge(
                    title: viewModel.gameBoard.generationQualityNote.contains("严格") ? "严格无猜盘面" : "回退增强盘面",
                    color: viewModel.gameBoard.generationQualityNote.contains("严格") ? .green : .orange
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .surfaceCard(radius: 16, fillColor: Color(.secondarySystemBackground).opacity(0.86), shadowOpacity: 0.03)
    }
}

struct GameBottomControlPanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Binding var showingNewGameConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    label: "新局",
                    isEnabled: true,
                    color: .blue
                ) {
                    if viewModel.isGameActive {
                        showingNewGameConfirmation = true
                    } else {
                        viewModel.newGame()
                    }
                }
                
                QuickActionButton(
                    icon: "arrow.uturn.backward",
                    label: "撤销",
                    isEnabled: viewModel.canUndo && viewModel.gameBoard.gameState == .playing && !viewModel.isPaused,
                    color: .indigo
                ) {
                    viewModel.undo()
                }
                
                QuickActionButton(
                    icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                    label: viewModel.isPaused ? "继续" : "暂停",
                    isEnabled: viewModel.isGameActive && viewModel.gameBoard.gameState == .playing,
                    color: viewModel.isPaused ? .green : .orange
                ) {
                    viewModel.togglePause()
                }
                
                QuickActionButton(
                    icon: "lightbulb.fill",
                    label: "提示",
                    isEnabled: viewModel.gameBoard.gameState == .playing && !viewModel.isPaused,
                    color: .yellow
                ) {
                    viewModel.showHint()
                }
            }
            .padding(10)
            .surfaceCard(radius: 16, fillColor: Color(.secondarySystemBackground).opacity(0.84), shadowOpacity: 0.02)
            
            HStack(spacing: 8) {
                InstructionChip(icon: "hand.tap", text: "点按翻开")
                InstructionChip(icon: "flag.fill", text: "长按插旗")
                InstructionChip(icon: "square.grid.3x3.fill", text: "双击快开")
                Spacer(minLength: 0)
                Text(viewModel.isPaused ? "已暂停" : (viewModel.gameBoard.gameState == .playing ? "进行中" : "已结束"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(viewModel.isPaused ? .orange : (viewModel.gameBoard.gameState == .playing ? .green : .secondary))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill((viewModel.isPaused ? Color.orange : Color.green).opacity(0.14))
                    )
            }
            .padding(.horizontal, 6)
            .padding(.top, 1)
        }
    }
}

struct GameBoardContainer: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    let boardHeaderReservedHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = max(geometry.size.height - boardHeaderReservedHeight, geometry.size.height * 0.9)
            let cols = CGFloat(viewModel.gameBoard.cols)
            let rows = CGFloat(viewModel.gameBoard.rows)
            let spacing: CGFloat = 2
            let totalSpacingX = (cols - 1) * spacing
            let totalSpacingY = (rows - 1) * spacing
            let cellWidth = (availableWidth - totalSpacingX) / cols
            let cellHeight = (availableHeight - totalSpacingY) / rows
            let cellSize = min(cellWidth, cellHeight, 104)
            let boardWidth = cols * cellSize + totalSpacingX
            let boardHeight = rows * cellSize + totalSpacingY
            let offsetX = max(0, (availableWidth - boardWidth) / 2)
            let offsetY = max(0, (availableHeight - boardHeight) / 2)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text("当前棋盘")
                        .font(.subheadline.weight(.bold))
                    Spacer(minLength: 0)
                    Text("\(viewModel.gameBoard.rows)×\(viewModel.gameBoard.cols)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.primary.opacity(0.05)))
                }
                
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
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(themeManager.gameTheme.boardBackgroundColor.opacity(0.99))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, offsetX)
                    .padding(.vertical, offsetY)
                }
            }
        }
    }
}

struct GameStatChip: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground).opacity(0.8))
        )
    }
}

struct ModeBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(color == .secondary ? .secondary : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((color == .secondary ? Color.gray : color).opacity(0.14))
            )
    }
}
