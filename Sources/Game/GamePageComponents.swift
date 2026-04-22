import SwiftUI

struct GameTopStatusBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    let statusTitle: String
    let statusSubtitle: String
    let statusColor: Color
    let progressText: String
    let modeBadgeColor: Color
    
    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 7, height: 7)
                    .overlay(
                        Circle()
                            .fill(statusColor)
                            .frame(width: 4, height: 4)
                    )
                Text(statusTitle)
                    .font(.caption2.weight(.bold))
                Text(progressText)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(statusColor)
            }
            
            CompactGameStatChip(
                icon: "flag.fill",
                iconColor: .red,
                value: "\(viewModel.remainingMines)"
            )
            
            CompactGameStatChip(
                icon: viewModel.challengeMode == .timed ? "timer" : "clock",
                iconColor: viewModel.challengeMode == .timed ? .orange : .blue,
                value: viewModel.challengeMode == .timed ? "\(viewModel.challengeSecondsRemaining)s" : viewModel.formattedTime
            )
            
            Spacer(minLength: 0)
            
            ModeBadge(
                title: viewModel.challengeMode == .none ? viewModel.difficulty.rawValue : viewModel.challengeMode.badgeTitle,
                color: modeBadgeColor
            )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .surfaceCard(radius: 10, fillColor: Color(.secondarySystemBackground).opacity(0.74), shadowOpacity: 0.01)
    }
}

struct GameBottomControlPanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Binding var showingNewGameConfirmation: Bool
    
    var body: some View {
        HStack(spacing: 6) {
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
            
            Text(viewModel.isPaused ? "暂停" : (viewModel.gameBoard.gameState == .playing ? "进行中" : "结束"))
                .font(.caption2.weight(.semibold))
                .foregroundColor(viewModel.isPaused ? .orange : (viewModel.gameBoard.gameState == .playing ? .green : .secondary))
                .padding(.leading, 2)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .surfaceCard(radius: 10, fillColor: Color(.secondarySystemBackground).opacity(0.72), shadowOpacity: 0.01)
    }
}

struct GameBoardContainer: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    let boardHeaderReservedHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = max(geometry.size.height - boardHeaderReservedHeight, geometry.size.height * 0.94)
            let cols = CGFloat(viewModel.gameBoard.cols)
            let rows = CGFloat(viewModel.gameBoard.rows)
            let spacing: CGFloat = 2
            let totalSpacingX = (cols - 1) * spacing
            let totalSpacingY = (rows - 1) * spacing
            let cellWidth = (availableWidth - totalSpacingX) / cols
            let cellHeight = (availableHeight - totalSpacingY) / rows
            let cellSize = min(cellWidth, cellHeight, 112)
            let boardWidth = cols * cellSize + totalSpacingX
            let boardHeight = rows * cellSize + totalSpacingY
            let offsetX = max(0, (availableWidth - boardWidth) / 2)
            let offsetY = max(0, (availableHeight - boardHeight) / 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text("棋盘")
                        .font(.caption.weight(.bold))
                    Spacer(minLength: 0)
                    Text("\(viewModel.gameBoard.rows)×\(viewModel.gameBoard.cols)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
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
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(themeManager.gameTheme.boardBackgroundColor.opacity(0.99))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, offsetX)
                    .padding(.vertical, offsetY)
                }
            }
        }
    }
}

struct CompactGameStatChip: View {
    let icon: String
    let iconColor: Color
    let value: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(iconColor)
            Text(value)
                .font(.caption2.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(.systemBackground).opacity(0.78))
        )
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
            .font(.caption2.weight(.semibold))
            .foregroundColor(color == .secondary ? .secondary : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill((color == .secondary ? Color.gray : color).opacity(0.14))
            )
    }
}
