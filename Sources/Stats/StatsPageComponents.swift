import SwiftUI

struct StatsHeroHeaderSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView("战绩总览", subtitle: "关键结果先看趋势，再看细项。")
            
            HStack(spacing: 10) {
                DashboardMiniCard(title: "总胜率", value: String(format: "%.1f%%", viewModel.gameStats.getWinRate()), color: .green)
                DashboardMiniCard(title: "打卡", value: "\(viewModel.gameStats.getDailyChallengeStreak())天", color: .orange)
            }
            HStack(spacing: 10) {
                DashboardMiniCard(title: "成就", value: "\(viewModel.gameStats.unlockedAchievementsCount())个", color: .yellow)
                DashboardMiniCard(title: "连胜", value: "\(viewModel.gameStats.bestWinStreak())局", color: .purple)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .surfaceCard(
            radius: 20,
            fillColor: themeManager.gameTheme == .cyber ? Color.white.opacity(0.08) : themeManager.gameTheme.pageCardFill,
            strokeOpacity: themeManager.gameTheme == .cyber ? 0.05 : 0.04,
            shadowOpacity: 0.03,
            shadowRadius: 14,
            shadowY: 6
        )
    }
}

struct StatsAchievementsSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView("成就", subtitle: "高光时刻卡片化收纳。")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.gameStats.achievements) { achievement in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: achievement.icon)
                                    .font(.subheadline)
                                    .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                                Spacer()
                                Text(achievement.isUnlocked ? "已解锁" : "未解锁")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(achievement.isUnlocked ? .green : .secondary)
                            }

                            Text(achievement.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)

                            Text(achievement.detail)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            Spacer(minLength: 0)
                        }
                        .frame(width: 156, height: 118, alignment: .leading)
                        .padding(10)
                        .surfaceCard(
                            radius: 14,
                            fillColor: themeManager.gameTheme.pageCardFill,
                            strokeOpacity: achievement.isUnlocked ? 0.18 : 0.05,
                            shadowOpacity: 0.03,
                            shadowRadius: 8,
                            shadowY: 3
                        )
                    }
                }
            }
        }
    }
}

struct StatsNoGuessSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let formatTime: (TimeInterval) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView("无猜挑战", subtitle: "看严格命中与回退比例。")
            
            VStack(alignment: .leading, spacing: 8) {
                StatsInfoRow(label: "对局数", systemImage: "brain.head.profile", value: "\(viewModel.gameStats.noGuessGames)")
                StatsInfoRow(label: "胜率", systemImage: "checkmark.seal", value: String(format: "%.1f%%", viewModel.gameStats.getNoGuessWinRate()), valueColor: .green)
                StatsInfoRow(label: "最佳时间", systemImage: "stopwatch", value: viewModel.gameStats.noGuessBestTime == nil ? "--:--" : formatTime(viewModel.gameStats.noGuessBestTime!))
                StatsInfoRow(label: "严格命中", systemImage: "shield.checkered", value: "\(viewModel.gameStats.noGuessStrictBoards)", valueColor: .green)
                StatsInfoRow(label: "回退生成", systemImage: "wand.and.stars", value: "\(viewModel.gameStats.noGuessFallbackBoards)", valueColor: .orange)
            }
            .padding(12)
            .surfaceCard(radius: 16, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.03)
        }
    }
}

struct StatsDailyChallengeSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let formatTime: (TimeInterval) -> String
    
    var body: some View {
        let todayStatus = viewModel.gameStats.getTodayDailyChallengeStatus()
        
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView("每日挑战", subtitle: "今日状态一眼可见。")
            
            VStack(alignment: .leading, spacing: 8) {
                StatsInfoRow(label: "今日状态", systemImage: todayStatus == nil ? "calendar.badge.clock" : "calendar.badge.checkmark", value: todayStatus == nil ? "未完成" : "已完成", valueColor: todayStatus == nil ? .secondary : .green)
                StatsInfoRow(label: "今日最佳", systemImage: "trophy", value: todayStatus == nil ? "--:--" : formatTime(todayStatus!.bestTime))
                StatsInfoRow(label: "连续打卡", systemImage: "flame.fill", value: "\(viewModel.gameStats.getDailyChallengeStreak()) 天", valueColor: .orange)
                StatsInfoRow(label: "累计完成", systemImage: "calendar.circle", value: "\(viewModel.gameStats.getDailyChallengeCompletedDays()) 天")
            }
            .padding(12)
            .surfaceCard(radius: 16, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.03)
        }
    }
}

struct StatsChallengeOverviewSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let challengeRecords = viewModel.gameStats.getChallengeRecords()
        
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView("挑战模式", subtitle: "单独看挑战表现，避免与普通对局混在一起。")
            
            if challengeRecords.isEmpty {
                Text("还没有挑战模式记录，去试试每日挑战或限时挑战吧。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .surfaceCard(radius: 18, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.04)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    StatsInfoRow(label: "挑战局数", systemImage: "flag.checkered", value: "\(challengeRecords.count)")
                    StatsInfoRow(label: "挑战胜率", systemImage: "sparkles", value: String(format: "%.1f%%", viewModel.gameStats.getChallengeWinRate()), valueColor: .green)
                    if let latest = challengeRecords.first {
                        StatsInfoRow(label: "最近挑战", systemImage: "calendar", value: latest.challengeMode ?? "挑战", valueColor: .secondary)
                    }
                }
                .padding(14)
                .surfaceCard(radius: 18, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.04)
            }
        }
    }
}

struct StatsDifficultyFilterSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedDifficulty: Difficulty?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView("难度筛选", subtitle: nil)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterButton(
                        title: "全部",
                        isSelected: selectedDifficulty == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDifficulty = nil
                        }
                    }
                    
                    ForEach(Difficulty.allCases) { difficulty in
                        FilterButton(
                            title: difficulty.rawValue,
                            isSelected: selectedDifficulty == difficulty
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDifficulty = difficulty
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .surfaceCard(radius: 14, fillColor: themeManager.gameTheme.pageInnerCardFill, shadowOpacity: 0.03)
    }
}

struct StatsBestTimesSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let difficultyColor: (Difficulty) -> Color
    let formatTime: (TimeInterval) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView("最佳时间", subtitle: "记录每个难度的峰值表现，便于长期追分。")
            
            VStack(spacing: 8) {
                ForEach(Difficulty.allCases) { difficulty in
                    if let bestTime = viewModel.gameStats.getBestTime(for: difficulty) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(difficultyColor(difficulty))
                                    .frame(width: 8, height: 8)
                                Text(difficulty.rawValue)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text(formatTime(bestTime))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(14)
            .surfaceCard(radius: 18, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.04)
        }
    }
}

struct StatsWinRateSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let difficultyColor: (Difficulty) -> Color
    let winRateColor: (Double) -> Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView("各难度胜率", subtitle: "用更清晰的进度条看长期趋势，而不是只看一次结果。")
            
            VStack(spacing: 12) {
                ForEach(Difficulty.allCases) { difficulty in
                    let winRate = viewModel.gameStats.getWinRate(for: difficulty)
                    let games = viewModel.gameStats.getRecords(for: difficulty).count
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(difficultyColor(difficulty))
                                    .frame(width: 8, height: 8)
                                Text(difficulty.rawValue)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(games) 场")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(winRateColor(winRate))
                                    .frame(width: geometry.size.width * CGFloat(winRate / 100), height: 8)
                                    .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.5) : nil, value: winRate)
                            }
                        }
                        .frame(height: 8)
                        
                        Text(String(format: "%.1f%%", winRate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            .surfaceCard(radius: 18, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.04)
        }
    }
}

struct StatsRecentGamesSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    let selectedDifficulty: Difficulty?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView("最近游戏", subtitle: "保留最近 10 局。")
            
            let records = selectedDifficulty != nil
                ? viewModel.gameStats.getRecords(for: selectedDifficulty)
                : viewModel.gameStats.records
            
            if records.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("暂无游戏记录")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text(selectedDifficulty == nil ? "先完成一局游戏，这里会展示最近战绩。" : "当前难度还没有记录。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 12)
                .surfaceCard(radius: 16, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.03)
            } else {
                VStack(spacing: 8) {
                    ForEach(records.prefix(10)) { record in
                        GameRecordRow(record: record)
                    }
                }
                .padding(10)
                .surfaceCard(radius: 16, fillColor: themeManager.gameTheme.pageCardFill, shadowOpacity: 0.03)
            }
        }
    }
}

struct DashboardMiniCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.gameTheme == .cyber ? Color.white.opacity(0.06) : themeManager.gameTheme.pageInnerCardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(themeManager.gameTheme == .cyber ? 0.12 : 0.08), lineWidth: 1)
        )
    }
}

struct StatsInfoRow: View {
    let label: String
    let systemImage: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 8) {
            Label(label, systemImage: systemImage)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(valueColor)
        }
    }
}
