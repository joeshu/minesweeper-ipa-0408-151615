import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDifficulty: Difficulty? = nil
    
    private var statsBackground: some View {
        Group {
            if themeManager.useGradientBackground {
                LinearGradient(
                    colors: [
                        themeManager.gameTheme.boardBackgroundColor.opacity(0.24),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(.systemBackground)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    StatsHeroHeaderSection()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                    StatsTacticalAssessmentsSection()
                        .environmentObject(viewModel)
                    overviewCards
                    StatsAchievementsSection()
                        .environmentObject(viewModel)
                    StatsNoGuessSection(formatTime: formatTime)
                        .environmentObject(viewModel)
                    StatsDailyChallengeSection(formatTime: formatTime)
                        .environmentObject(viewModel)
                    StatsChallengeOverviewSection()
                        .environmentObject(viewModel)
                    StatsDifficultyFilterSection(selectedDifficulty: $selectedDifficulty)
                    StatsBestTimesSection(difficultyColor: difficultyColor, formatTime: formatTime)
                        .environmentObject(viewModel)
                    StatsWinRateSection(difficultyColor: difficultyColor, winRateColor: winRateColor)
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                    StatsRecentGamesSection(selectedDifficulty: selectedDifficulty)
                        .environmentObject(viewModel)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(statsBackground.ignoresSafeArea())
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
        }
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
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(record.challengeMode ?? record.difficulty)
                        .font(.caption.weight(.semibold))
                    Text(record.difficulty)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(.systemGray5)))
                }

                Text(formattedDate(record.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\(record.rows)×\(record.cols) · \(record.mineCount)雷")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: record.result == .won ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.result == .won ? .green : .red)
                        .font(.caption2)
                    Text(record.result == .won ? "胜利" : "失败")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(record.result == .won ? .green : .red)
                }

                Text(formatTime(record.duration))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
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
