import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showResetConfirmation = false
    @State private var showClearStatsConfirmation = false
    
    private var settingsGradient: some View {
        LinearGradient(
            colors: [
                themeManager.gameTheme.boardBackgroundColor.opacity(0.22),
                Color(.systemBackground)
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
                    settingsOverviewSection
                }
                
                Section {
                    difficultySectionContent
                } header: {
                    SectionHeaderView("游戏难度", subtitle: "优先保证上手清晰，再去调高策略密度。")
                }
                
                if viewModel.difficulty == .custom {
                    Section {
                        customBoardSectionContent
                    } header: {
                        SectionHeaderView("自定义棋盘", subtitle: "把常玩的尺寸保存成预设，减少重复调参。")
                    }
                }
                
                Section {
                    challengeModesSectionContent
                } header: {
                    SectionHeaderView("挑战模式", subtitle: "根据目标切换玩法，产品体验会优先突出当前模式。")
                }
                
                Section {
                    appearanceSectionContent
                } header: {
                    SectionHeaderView("外观", subtitle: "优先保证层级清晰和阅读舒适，再决定是否加动画。")
                }
                
                Section {
                    soundSectionContent
                } header: {
                    SectionHeaderView("声音", subtitle: "保留轻量反馈，不要让声音抢走判断注意力。")
                }
                
                Section {
                    hapticSectionContent
                } header: {
                    SectionHeaderView("触觉反馈", subtitle: "插旗、胜负和关键操作通过触觉建立即时确认。")
                }
                
                Section(footer: Text("清除后将删除本机所有历史战绩与成就解锁进度，且无法恢复。")) {
                    statsSectionContent
                } header: {
                    SectionHeaderView("游戏统计", subtitle: "这里适合定期清理，保持试验体验和正式记录分开。")
                }
                
                Section {
                    aboutSectionContent
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
    
    private var settingsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderView("当前配置", subtitle: "快速查看模式、主题、声音与操作反馈是否符合当前手感。")
            HStack {
                settingsPill(title: viewModel.challengeMode.rawValue, color: .blue)
                settingsPill(title: themeManager.gameTheme.rawValue, color: .green)
                settingsPill(title: viewModel.soundManager.isSoundEnabled ? "音效开" : "音效关", color: .orange)
            }
            Text("现在使用 \(viewModel.difficulty.rawValue) 难度，界面与反馈已按产品化方向统一整理。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var difficultySectionContent: some View {
        Group {
            Picker("难度", selection: Binding(
                get: { viewModel.difficulty },
                set: { viewModel.setDifficulty($0) }
            )) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.rawValue)
                        .tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.difficulty.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if viewModel.difficulty == .custom {
                    Label(customConfigSummary, systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .surfaceCard(radius: 14, fillColor: Color(.secondarySystemBackground).opacity(0.78), shadowOpacity: 0)
        }
    }
    
    private var customBoardSectionContent: some View {
        Group {
            StepperView(
                title: "行数",
                value: Binding(
                    get: { viewModel.customRows },
                    set: { newValue in
                        viewModel.updateCustomSettings(
                            rows: newValue,
                            cols: viewModel.customCols,
                            mines: viewModel.customMines
                        )
                    }
                ),
                range: 5...30
            )
            
            StepperView(
                title: "列数",
                value: Binding(
                    get: { viewModel.customCols },
                    set: { newValue in
                        viewModel.updateCustomSettings(
                            rows: viewModel.customRows,
                            cols: newValue,
                            mines: viewModel.customMines
                        )
                    }
                ),
                range: 5...30
            )
            
            StepperView(
                title: "地雷数",
                value: Binding(
                    get: { viewModel.customMines },
                    set: { newValue in
                        viewModel.updateCustomSettings(
                            rows: viewModel.customRows,
                            cols: viewModel.customCols,
                            mines: newValue
                        )
                    }
                ),
                range: 1...(viewModel.customRows * viewModel.customCols - 9)
            )
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前配置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(customConfigSummary)
                        .font(.headline)
                    Text("雷密度：\(String(format: "%.1f", viewModel.customMineDensity * 100))%")
                        .font(.caption)
                        .foregroundColor(viewModel.customMineDensity > 0.22 ? .orange : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .surfaceCard(radius: 14, fillColor: Color(.secondarySystemBackground).opacity(0.82), shadowOpacity: 0)
                
                TextField("预设名称", text: $viewModel.presetNameDraft)
                    .textInputAutocapitalization(.never)
                
                Button {
                    viewModel.saveCurrentAsPreset()
                } label: {
                    Label("保存为预设", systemImage: "square.and.arrow.down")
                }
                
                if !viewModel.customPresets.isEmpty {
                    Text("已保存预设")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.customPresets) { preset in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                Text(preset.summary)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("应用") {
                                viewModel.applyCustomPreset(preset)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button(role: .destructive) {
                                viewModel.deleteCustomPreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var challengeModesSectionContent: some View {
        Group {
            if viewModel.gameStats.getTodayDailyChallengeStatus() != nil {
                Label("每日挑战今日已完成", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 10) {
                ForEach(ChallengeMode.allCases) { mode in
                    Button {
                        viewModel.setChallengeMode(mode)
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(challengeModeColor(mode).opacity(0.15))
                                    .frame(width: 34, height: 34)
                                Image(systemName: challengeModeIcon(mode))
                                    .foregroundColor(challengeModeColor(mode))
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(mode.rawValue)
                                        .foregroundColor(.primary)
                                        .fontWeight(.semibold)
                                    if viewModel.challengeMode == mode {
                                        Text("当前")
                                            .font(.caption2)
                                            .foregroundColor(challengeModeColor(mode))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(challengeModeColor(mode).opacity(0.12)))
                                    }
                                }
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .surfaceCard(
                            radius: 14,
                            fillColor: viewModel.challengeMode == mode ? challengeModeColor(mode).opacity(0.08) : Color(.secondarySystemBackground).opacity(0.82),
                            shadowOpacity: 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var appearanceSectionContent: some View {
        Group {
            Picker("应用主题", selection: Binding(
                get: { themeManager.appTheme },
                set: { themeManager.setAppTheme($0) }
            )) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.rawValue)
                        .tag(theme)
                }
            }
            
            Picker("游戏主题", selection: Binding(
                get: { themeManager.gameTheme },
                set: { themeManager.setGameTheme($0) }
            )) {
                ForEach(GameTheme.allCases) { theme in
                    HStack {
                        Circle()
                            .fill(theme.cellHiddenColor)
                            .frame(width: 12, height: 12)
                        Text(theme.rawValue)
                    }
                    .tag(theme)
                }
            }
            
            Toggle("渐变背景", isOn: Binding(
                get: { themeManager.useGradientBackground },
                set: { themeManager.setUseGradientBackground($0) }
            ))
            
            Toggle("动画效果", isOn: Binding(
                get: { themeManager.enableAnimations },
                set: { themeManager.setEnableAnimations($0) }
            ))
        }
    }
    
    private var soundSectionContent: some View {
        Group {
            Toggle("启用音效", isOn: Binding(
                get: { viewModel.soundManager.isSoundEnabled },
                set: { _ in viewModel.soundManager.toggleSound() }
            ))
            
            if viewModel.soundManager.isSoundEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.secondary)
                        Slider(value: Binding(
                            get: { viewModel.soundManager.volume },
                            set: { viewModel.soundManager.setVolume($0) }
                        ), in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("音量: \(Int(viewModel.soundManager.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var hapticSectionContent: some View {
        Toggle("启用触觉反馈", isOn: Binding(
            get: { viewModel.hapticManager.isHapticEnabled },
            set: { _ in viewModel.hapticManager.toggleHaptic() }
        ))
    }
    
    private var statsSectionContent: some View {
        Group {
            StatRow(title: "总游戏数", value: "\(viewModel.gameStats.totalGames)")
            StatRow(title: "胜利次数", value: "\(viewModel.gameStats.wins)", valueColor: .green)
            StatRow(title: "失败次数", value: "\(viewModel.gameStats.losses)", valueColor: .red)
            StatRow(title: "胜率", value: String(format: "%.1f%%", viewModel.gameStats.getWinRate()))
            
            Button(role: .destructive) {
                showClearStatsConfirmation = true
            } label: {
                Label("清除所有记录", systemImage: "trash")
            }
            .disabled(viewModel.gameStats.totalGames == 0)
        }
    }
    
    private var aboutSectionContent: some View {
        Group {
            HStack {
                Text("版本")
                Spacer()
                Text("2.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("开发者")
                Spacer()
                Text("Minesweeper Team")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://github.com")!) {
                HStack {
                    Text("GitHub")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func challengeModeColor(_ mode: ChallengeMode) -> Color {
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
    private func settingsPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

struct StepperView: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        Stepper {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
            }
        } onIncrement: {
            if value < range.upperBound {
                value += 1
            }
        } onDecrement: {
            if value > range.lowerBound {
                value -= 1
            }
        }
    }
}

// MARK: - StatRow
struct StatRow: View {
    let title: String
    let value: String
    var valueColor: Color = .secondary
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
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
