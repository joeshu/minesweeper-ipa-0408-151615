import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDifficulty: Difficulty? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    statsHeroHeader
                    
                    // 概览卡片
                    overviewCards
                    
                    // 成就系统
                    achievementsSection
                    
                    // 无猜模式统计
                    noGuessSection
                    
                    // 每日挑战状态
                    dailyChallengeSection
                    
                    // 挑战模式统计
                    challengeOverviewSection
                    
                    // 难度选择器
                    difficultySelector
                    
                    // 最佳时间
                    bestTimesSection
                    
                    // 胜率统计
                    winRateSection
                    
                    // 最近游戏记录
                    recentGamesSection
                }
                .padding()
            }
            .background(
                themeManager.useGradientBackground ?
                LinearGradient(
                    colors: [
                        themeManager.gameTheme.boardBackgroundColor.opacity(0.3),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea() : nil
            )
        }
    }
    
    // MARK: - 仪表盘头部
    private var statsHeroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("战绩总览")
                .font(.title3.weight(.bold))
            Text("快速查看总体胜率、每日挑战进度与无猜模式表现。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    dashboardMiniCard(title: "总胜率", value: String(format: "%.1f%%", viewModel.gameStats.getWinRate()), color: .green)
                    dashboardMiniCard(title: "打卡", value: "\(viewModel.gameStats.getDailyChallengeStreak())天", color: .orange)
                }
                HStack(spacing: 10) {
                    dashboardMiniCard(title: "成就", value: "\(viewModel.gameStats.unlockedAchievementsCount())个", color: .yellow)
                    dashboardMiniCard(title: "连胜", value: "\(viewModel.gameStats.bestWinStreak())局", color: .purple)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func dashboardMiniCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.85))
        )
    }
    
    // MARK: - 概览卡片
    private var overviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "总游戏数",
                value: "\(viewModel.gameStats.totalGames)",
                icon: "number.circle.fill",
                color: .blue
            )
            
            StatCard(
                title: "胜率",
                value: String(format: "%.1f%%", viewModel.gameStats.getWinRate()),
                icon: "percent",
                color: .green
            )
            
            StatCard(
                title: "胜利次数",
                value: "\(viewModel.gameStats.wins)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "失败次数",
                value: "\(viewModel.gameStats.losses)",
                icon: "xmark.circle.fill",
                color: .red
            )
        }
    }
    

    // MARK: - 成就系统
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.gameStats.achievements) { achievement in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: achievement.icon)
                                    .font(.title3)
                                    .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                                Spacer()
                                Text(achievement.isUnlocked ? "已解锁" : "未解锁")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(achievement.isUnlocked ? .green : .secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(achievement.isUnlocked ? Color.green.opacity(0.12) : Color(.systemGray5))
                                    )
                            }

                            Text(achievement.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)

                            Text(achievement.detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            Spacer(minLength: 0)
                        }
                        .frame(width: 170, height: 140, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(achievement.isUnlocked ? Color.yellow.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 无猜模式统计
    private var noGuessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("无猜挑战")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("对局数", systemImage: "brain.head.profile")
                    Spacer()
                    Text("\(viewModel.gameStats.noGuessGames)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("胜率", systemImage: "checkmark.seal")
                    Spacer()
                    Text(String(format: "%.1f%%", viewModel.gameStats.getNoGuessWinRate()))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Label("最佳时间", systemImage: "stopwatch")
                    Spacer()
                    Text(viewModel.gameStats.noGuessBestTime == nil ? "--:--" : formatTime(viewModel.gameStats.noGuessBestTime!))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("严格命中", systemImage: "shield.checkered")
                    Spacer()
                    Text("\(viewModel.gameStats.noGuessStrictBoards)")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Label("回退生成", systemImage: "wand.and.stars")
                    Spacer()
                    Text("\(viewModel.gameStats.noGuessFallbackBoards)")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - 每日挑战状态
    private var dailyChallengeSection: some View {
        let todayStatus = viewModel.gameStats.getTodayDailyChallengeStatus()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("每日挑战")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("今日状态", systemImage: todayStatus == nil ? "calendar.badge.clock" : "calendar.badge.checkmark")
                    Spacer()
                    Text(todayStatus == nil ? "未完成" : "已完成")
                        .foregroundColor(todayStatus == nil ? .secondary : .green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("今日最佳", systemImage: "trophy")
                    Spacer()
                    Text(todayStatus == nil ? "--:--" : formatTime(todayStatus!.bestTime))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("连续打卡", systemImage: "flame.fill")
                    Spacer()
                    Text("\(viewModel.gameStats.getDailyChallengeStreak()) 天")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Label("累计完成", systemImage: "calendar.circle")
                    Spacer()
                    Text("\(viewModel.gameStats.getDailyChallengeCompletedDays()) 天")
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - 挑战概览
    private var challengeOverviewSection: some View {
        let challengeRecords = viewModel.gameStats.getChallengeRecords()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("挑战模式")
                .font(.headline)
            
            if challengeRecords.isEmpty {
                Text("还没有挑战模式记录，去试试每日挑战或限时挑战吧。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("挑战局数", systemImage: "flag.checkered")
                        Spacer()
                        Text("\(challengeRecords.count)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Label("挑战胜率", systemImage: "sparkles")
                        Spacer()
                        Text(String(format: "%.1f%%", viewModel.gameStats.getChallengeWinRate()))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    if let latest = challengeRecords.first {
                        HStack {
                            Label("最近挑战", systemImage: "calendar")
                            Spacer()
                            Text(latest.challengeMode ?? "挑战")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
    
    // MARK: - 难度选择器
    private var difficultySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择难度")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
    }
    
    // MARK: - 最佳时间
    private var bestTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最佳时间")
                .font(.headline)
            
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - 胜率统计
    private var winRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("各难度胜率")
                .font(.headline)
            
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - 最近游戏记录
    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近游戏")
                .font(.headline)
            
            let records = selectedDifficulty != nil 
                ? viewModel.gameStats.getRecords(for: selectedDifficulty)
                : viewModel.gameStats.records
            
            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无游戏记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(records.prefix(10)) { record in
                        GameRecordRow(record: record)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .custom: return .purple
        }
    }
    
    private func winRateColor(_ winRate: Double) -> Color {
        if winRate >= 70 {
            return .green
        } else if winRate >= 40 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - 游戏记录行
struct GameRecordRow: View {
    let record: GameRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(record.challengeMode ?? record.difficulty)
                        .font(.subheadline.weight(.semibold))
                    Text(record.difficulty)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(.systemGray5)))
                }

                Text(formattedDate(record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(record.rows)×\(record.cols) · \(record.mineCount)雷")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: record.result == .won ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.result == .won ? .green : .red)
                        .font(.caption)
                    Text(record.result == .won ? "胜利" : "失败")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(record.result == .won ? .green : .red)
                }

                Text(formatTime(record.duration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(GameViewModel())
            .environmentObject(ThemeManager.shared)
    }
}
