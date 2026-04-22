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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(statusColor.opacity(0.18))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 5, height: 5)
                            )
                        
                        Text(themeManager.gameTheme == .cyber ? "TACTICAL COMMAND" : "对局状态")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.gameTheme == .cyber ? Color(red: 0.24, green: 0.55, blue: 0.76) : .secondary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(statusTitle)
                            .font(.title2.weight(.bold))
                            .foregroundColor(themeManager.gameTheme == .cyber ? Color(red: 0.14, green: 0.22, blue: 0.32) : .primary)
                        Text(progressText)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(statusColor.opacity(0.12)))
                    }
                    
                    Text(statusSubtitle)
                        .font(themeManager.gameTheme == .cyber ? .system(size: 12.5, weight: .medium, design: .rounded) : .subheadline)
                        .foregroundColor(themeManager.gameTheme == .cyber ? Color(red: 0.40, green: 0.50, blue: 0.60) : .secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
                
                ModeBadge(
                    title: viewModel.modeProtocolLabel,
                    color: modeBadgeColor
                )
            }
            
            HStack(spacing: 10) {
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
                
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(cardBackground)
        .overlay(cardOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if themeManager.gameTheme == .cyber {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.78),
                    Color(red: 0.86, green: 0.95, blue: 1.0).opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.8))
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 17, style: .continuous)
            .stroke(themeManager.gameTheme == .cyber ? Color(red: 0.28, green: 0.66, blue: 0.88).opacity(0.18) : Color.primary.opacity(0.05), lineWidth: 1)
    }
}

struct GameBottomControlPanel: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingNewGameConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("快速操作")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(themeManager.gameTheme == .cyber ? Color(red: 0.18, green: 0.30, blue: 0.42) : .primary)
                
                Text(viewModel.isPaused ? "暂停中" : (viewModel.gameBoard.gameState == .playing ? "对局进行中" : "等待下一局"))
                    .font(.caption.weight(.medium))
                    .foregroundColor(viewModel.isPaused ? .orange : (viewModel.gameBoard.gameState == .playing ? .green : .secondary))
                
                Spacer(minLength: 0)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("主操作")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
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
                    }
                    .padding(.vertical, 1)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("辅助操作")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .surfaceCard(
            radius: 16,
            fillColor: themeManager.gameTheme == .cyber ? Color.white.opacity(0.58) : Color(.secondarySystemBackground).opacity(0.74),
            strokeOpacity: themeManager.gameTheme == .cyber ? 0.05 : 0.06,
            shadowOpacity: themeManager.gameTheme == .cyber ? 0.02 : 0.01,
            shadowRadius: 16,
            shadowY: 6
        )
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
            let boardHeaderHeight: CGFloat = hasBoardInsights ? 84 : 42
            let boardInnerPadding: CGFloat = 6
            let boardAreaHeight = max(availableHeight - boardHeaderHeight - boardInnerPadding * 2, availableHeight * 0.83)
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
        VStack(alignment: .leading, spacing: hasBoardInsights ? 9 : 5) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(themeManager.gameTheme == .cyber ? "战术棋盘" : "棋盘区")
                        .font(.caption.weight(.bold))
                        .foregroundColor(themeManager.gameTheme == .cyber ? Color(red: 0.20, green: 0.38, blue: 0.54) : .primary)
                    if themeManager.gameTheme == .cyber {
                        Text("AURORA GRID")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.32, green: 0.62, blue: 0.82))
                    }
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 6) {
                    BoardMetaChip(
                        title: "尺寸",
                        value: "\(viewModel.gameBoard.rows)×\(viewModel.gameBoard.cols)",
                        accent: themeManager.gameTheme == .cyber ? Color(red: 0.30, green: 0.68, blue: 0.88) : .secondary
                    )
                    
                    BoardMetaChip(
                        title: "地雷",
                        value: "\(viewModel.gameBoard.totalMines)",
                        accent: .orange
                    )
                }
            }
            
            if hasBoardInsights {
                VStack(spacing: 7) {
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
        .padding(.horizontal, 2)
    }
    
    @ViewBuilder
    private var boardSurface: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                themeManager.gameTheme == .cyber
                ? LinearGradient(
                    colors: [
                        Color.white.opacity(0.70),
                        Color(red: 0.84, green: 0.94, blue: 1.0).opacity(0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        themeManager.gameTheme.boardBackgroundColor.opacity(0.99),
                        themeManager.gameTheme.boardBackgroundColor.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(themeManager.gameTheme == .cyber ? Color(red: 0.26, green: 0.66, blue: 0.90).opacity(0.14) : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(themeManager.gameTheme == .cyber ? 0.05 : 0.10), radius: 12, x: 0, y: 6)
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(themeManager.gameTheme == .cyber ? 0.58 : 0.48))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(themeManager.gameTheme == .cyber ? 0.18 : 0.10), lineWidth: 1)
        )
    }
}

struct BoardMetaChip: View {
    let title: String
    let value: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.46))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
    }
}

struct CompactGameStatChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let icon: String
    let iconColor: Color
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundColor(iconColor)
            Text(value)
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(themeManager.gameTheme == .cyber ? Color.white.opacity(0.72) : Color(.systemBackground).opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.primary.opacity(themeManager.gameTheme == .cyber ? 0.06 : 0.04), lineWidth: 1)
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
