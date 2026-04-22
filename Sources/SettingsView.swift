import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showResetConfirmation = false
    @State private var showClearStatsConfirmation = false
    
    private var settingsGradient: some View {
        LinearGradient(
            colors: [
                themeManager.gameTheme.pageTopTint,
                themeManager.gameTheme.pageBottomTint
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var customConfigSummary: String {
        "\(viewModel.customRows) × \(viewModel.customCols) · \(viewModel.customMines) 雷"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SettingsOverviewSection()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                }
                
                Section {
                    SettingsDifficultySection(customConfigSummary: customConfigSummary)
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                } header: {
                    SectionHeaderView("游戏难度", subtitle: "优先保证上手清晰，再去调高策略密度。")
                }
                
                if viewModel.difficulty == .custom {
                    Section {
                        SettingsCustomBoardSection(customConfigSummary: customConfigSummary)
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                    } header: {
                        SectionHeaderView("自定义棋盘", subtitle: "把常玩的尺寸保存成预设，减少重复调参。")
                    }
                }
                
                Section {
                    SettingsChallengeModesSection(
                        challengeModeColor: challengeModeColor,
                        challengeModeIcon: challengeModeIcon
                    )
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                } header: {
                    SectionHeaderView("挑战模式", subtitle: "根据目标切换玩法，产品体验会优先突出当前模式。")
                }
                
                Section {
                    SettingsAppearanceSection()
                        .environmentObject(themeManager)
                } header: {
                    SectionHeaderView("外观", subtitle: "优先保证层级清晰和阅读舒适，再决定是否加动画。")
                }
                
                Section {
                    SettingsSoundSection()
                        .environmentObject(viewModel)
                } header: {
                    SectionHeaderView("声音", subtitle: "保留轻量反馈，不要让声音抢走判断注意力。")
                }
                
                Section {
                    SettingsHapticSection()
                        .environmentObject(viewModel)
                } header: {
                    SectionHeaderView("触觉反馈", subtitle: "插旗、胜负和关键操作通过触觉建立即时确认。")
                }
                
                Section {
                    SettingsStatsSection(showClearStatsConfirmation: $showClearStatsConfirmation)
                        .environmentObject(viewModel)
                } header: {
                    SectionHeaderView("游戏统计", subtitle: "这里适合定期清理，保持试验体验和正式记录分开。")
                } footer: {
                    Text("清除后将删除本机所有历史战绩与成就解锁进度，且无法恢复。")
                }
                
                Section {
                    SettingsAboutSection()
                } header: {
                    SectionHeaderView("关于", subtitle: "项目入口和版本信息统一收口到这里。")
                }
            }
            .scrollContentBackground(.hidden)
            .background(settingsGradient.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .alert("确认清除", isPresented: $showClearStatsConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    viewModel.gameStats.clearAllRecords()
                }
            } message: {
                Text(viewModel.gameStats.totalGames == 0 ? "当前没有可清除的游戏记录。" : "确定要清除所有游戏记录吗？此操作会同时清空历史战绩与成就进度，且无法撤销。")
            }
        }
    }
    
    private func challengeModeColor(_ mode: ChallengeMode) -> Color {
        if themeManager.gameTheme == .cyber {
            switch mode {
            case .none: return .cyan
            case .daily: return .purple
            case .timed: return .pink
            case .noGuess: return .green
            }
        }
        switch mode {
        case .none: return .blue
        case .daily: return .purple
        case .timed: return .orange
        case .noGuess: return .green
        }
    }
    
    private func challengeModeIcon(_ mode: ChallengeMode) -> String {
        switch mode {
        case .none: return "gamecontroller.fill"
        case .daily: return "calendar"
        case .timed: return "timer"
        case .noGuess: return "brain.head.profile"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(GameViewModel())
            .environmentObject(ThemeManager.shared)
    }
}
