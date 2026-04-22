import SwiftUI

struct GameTopStatusBar: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    let statusTitle: String
    let statusSubtitle: String
    let statusColor: Color
    let progressText: String
    let modeBadgeColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor.opacity(0.18))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(statusColor)
                                .frame(width: 4.5, height: 4.5)
                        )
                    Text(statusTitle)
                        .font(.caption.weight(.bold))
                    Text(progressText)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(statusColor)
                }
                
                Text(statusSubtitle)
                    .font(themeManager.gameTheme == .cyber ? .system(size: 10, weight: .medium, design: .rounded) : .caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 5) {
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
                
                if viewModel.scanUsesRemaining > 0 {
                    CompactGameStatChip(
                        icon: "wave.3.right.circle.fill",
                        iconColor: .cyan,
                        value: "\(viewModel.scanUsesRemaining)"
                    )
                }
                
                ModeBadge(
                    title: viewModel.modeProtocolLabel,
                    color: modeBadgeColor
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(cardBackground)
        .overlay(cardOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if themeManager.gameTheme == .cyber {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.9),
                    Color(red: 0.88, green: 0.96, blue: 1.0).opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.74))
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(themeManager.gameTheme == .cyber ? Color(red: 0.34, green: 0.74, blue: 0.94).opacity(0.22) : Color.primary.opacity(0.04), lineWidth: 1)
    }
}

struct GameBottomControlPanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Binding var showingNewGameConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("快速操作")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(viewModel.isPaused ? "暂停中" : (viewModel.gameBoard.gameState == .playing ? "对局进行中" : "等待下一局"))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(viewModel.isPaused ? .orange : (viewModel.gameBoard.gameState == .playing ? .green : .secondary))
                
                Spacer(minLength: 0)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
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
                    
                    QuickActionButton(
                        icon: "wave.3.right.circle.fill",
                        label: "扫描",
                        isEnabled: viewModel.gameBoard.gameState == .playing && !viewModel.isPaused && viewModel.scanUsesRemaining > 0,
                        color: .cyan
                    ) {
                        viewModel.activateScanOverlay()
                    }
                    
                    QuickActionButton(
                        icon: "point.3.filled.connected.trianglepath.dotted",
                        label: "链路",
                        isEnabled: viewModel.gameBoard.gameState == .playing && !viewModel.isPaused,
                        color: .mint
                    ) {
                        viewModel.activateLogicChainHighlight()
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .surfaceCard(radius: 12, fillColor: Color(.secondarySystemBackground).opacity(0.72), shadowOpacity: 0.01)
    }
}

struct FuturisticSummaryStrip: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    let trailingText: String?
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.opacity(themeManager.gameTheme == .cyber ? 0.12 : 0.16))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundColor(accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 6)
            
            if let trailingText, !trailingText.isEmpty {
                Text(trailingText)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent.opacity(themeManager.gameTheme == .cyber ? 0.10 : 0.12)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(summaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(themeManager.gameTheme == .cyber ? accent.opacity(0.22) : Color.primary.opacity(0.04), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    @ViewBuilder
    private var summaryBackground: some View {
        if themeManager.gameTheme == .cyber {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.9),
                    accent.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.76))
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
            let availableHeight = max(geometry.size.height - boardHeaderReservedHeight, geometry.size.height * 0.94)
            let cols = CGFloat(viewModel.gameBoard.cols)
            let rows = CGFloat(viewModel.gameBoard.rows)
            let spacing: CGFloat = 2
            let totalSpacingX = (cols - 1) * spacing
            let totalSpacingY = (rows - 1) * spacing
            let boardHeaderHeight: CGFloat = hasBoardInsights ? 66 : 34
            let boardInnerPadding: CGFloat = 6
            let boardAreaHeight = max(availableHeight - boardHeaderHeight - boardInnerPadding * 2, availableHeight * 0.84)
            let cellWidth = (availableWidth - totalSpacingX - boardInnerPadding * 2) / cols
            let cellHeight = (boardAreaHeight - totalSpacingY) / rows
            let cellSize = min(cellWidth, cellHeight, 112)
            let boardWidth = cols * cellSize + totalSpacingX
            let boardHeight = rows * cellSize + totalSpacingY
            let offsetX = max(0, (availableWidth - boardWidth - boardInnerPadding * 2) / 2)
            let offsetY = max(0, (boardAreaHeight - boardHeight) / 2)
            
            VStack(alignment: .leading, spacing: 8) {
                boardHeader
                
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    LazyVStack(spacing: spacing) {
                        ForEach(0..<viewModel.gameBoard.rows, id: \.self) { row in
                            LazyHStack(spacing: spacing) {
                                ForEach(0..<viewModel.gameBoard.cols, id: \.self) { col in
                                    let cell = viewModel.gameBoard.cells[row][col]
                                    let isHint = viewModel.isShowingHint &&
                                                viewModel.hintPosition?.row == row &&
                                                viewModel.hintPosition?.col == col
                                    let isChainHighlight = viewModel.chainHighlights.contains { $0.row == row && $0.col == col }
                                    
                                    CellView(
                                        cell: cell,
                                        cellSize: cellSize,
                                        isHint: isHint,
                                        isScanOverlayVisible: viewModel.isScanOverlayVisible,
                                        isChainHighlight: isChainHighlight,
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
                    .padding(boardInnerPadding)
                    .padding(.horizontal, offsetX)
                    .padding(.vertical, offsetY)
                }
            }
            .padding(8)
            .background(boardSurface)
        }
    }
    
    private var hasBoardInsights: Bool {
        viewModel.scanRiskSummary != nil || viewModel.chainSummary != nil
    }
    
    private var boardHeader: some View {
        VStack(alignment: .leading, spacing: hasBoardInsights ? 8 : 4) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(themeManager.gameTheme == .cyber ? "战术棋盘" : "棋盘")
                        .font(.caption.weight(.bold))
                    if themeManager.gameTheme == .cyber {
                        Text("AURORA GRID")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.28, green: 0.66, blue: 0.88))
                    }
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 6) {
                    Text("\(viewModel.gameBoard.rows)×\(viewModel.gameBoard.cols)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(themeManager.gameTheme == .cyber ? Color(red: 0.28, green: 0.74, blue: 0.94).opacity(0.10) : Color.primary.opacity(0.05)))
                    
                    Text("\(viewModel.gameBoard.totalMines)雷")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.primary.opacity(0.04)))
                }
            }
            
            if hasBoardInsights {
                VStack(spacing: 6) {
                    if let summary = viewModel.scanRiskSummary {
                        BoardInsightRow(
                            icon: "wave.3.right.circle.fill",
                            title: summary.title,
                            detail: summary.detail,
                            accent: summary.tone == .safe ? .green : .cyan,
                            tag: "SCAN"
                        )
                    }
                    
                    if let summary = viewModel.chainSummary {
                        BoardInsightRow(
                            icon: "point.3.filled.connected.trianglepath.dotted",
                            title: summary.title,
                            detail: summary.detail,
                            accent: .mint,
                            tag: summary.emphasis
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var boardSurface: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(themeManager.gameTheme.boardBackgroundColor.opacity(0.99))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(themeManager.gameTheme == .cyber ? Color(red: 0.30, green: 0.72, blue: 0.94).opacity(0.16) : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(themeManager.gameTheme == .cyber ? 0.08 : 0.10), radius: 10, x: 0, y: 5)
    }
}

struct BoardInsightRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    let tag: String?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            if let tag, !tag.isEmpty {
                Text(tag)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent.opacity(themeManager.gameTheme == .cyber ? 0.10 : 0.12)))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(themeManager.gameTheme == .cyber ? 0.55 : 0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(themeManager.gameTheme == .cyber ? 0.18 : 0.10), lineWidth: 1)
        )
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
