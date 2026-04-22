import SwiftUI

struct SettingsOverviewSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView("当前配置", subtitle: nil)
            HStack(spacing: 6) {
                SettingsPill(title: viewModel.challengeMode.rawValue, color: .blue)
                SettingsPill(title: themeManager.gameTheme.rawValue, color: .green)
                SettingsPill(title: viewModel.soundManager.isSoundEnabled ? "音效开" : "音效关", color: .orange)
            }
        }
        .padding(.vertical, 2)
    }
}

struct SettingsDifficultySection: View {
    @EnvironmentObject var viewModel: GameViewModel
    let customConfigSummary: String
    
    var body: some View {
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
            
            HStack(spacing: 8) {
                Text(viewModel.difficulty.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if viewModel.difficulty == .custom {
                    Label(customConfigSummary, systemImage: "slider.horizontal.3")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .surfaceCard(radius: 12, fillColor: Color(.secondarySystemBackground).opacity(0.76), shadowOpacity: 0)
        }
    }
}

struct SettingsCustomBoardSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    let customConfigSummary: String
    
    var body: some View {
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
            
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前配置")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(customConfigSummary)
                        .font(.subheadline.weight(.semibold))
                    Text("雷密度：\(String(format: "%.1f", viewModel.customMineDensity * 100))%")
                        .font(.caption2)
                        .foregroundColor(viewModel.customMineDensity > 0.22 ? .orange : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .surfaceCard(radius: 12, fillColor: Color(.secondarySystemBackground).opacity(0.8), shadowOpacity: 0)
                
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
}

struct SettingsChallengeModesSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    let challengeModeColor: (ChallengeMode) -> Color
    let challengeModeIcon: (ChallengeMode) -> String
    
    var body: some View {
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
                        .padding(10)
                        .surfaceCard(
                            radius: 12,
                            fillColor: viewModel.challengeMode == mode ? challengeModeColor(mode).opacity(0.08) : Color(.secondarySystemBackground).opacity(0.8),
                            shadowOpacity: 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SettingsAppearanceSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
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
}

struct SettingsSoundSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
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
}

struct SettingsHapticSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        Toggle("启用触觉反馈", isOn: Binding(
            get: { viewModel.hapticManager.isHapticEnabled },
            set: { _ in viewModel.hapticManager.toggleHaptic() }
        ))
    }
}

struct SettingsStatsSection: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Binding var showClearStatsConfirmation: Bool
    
    var body: some View {
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
}

struct SettingsAboutSection: View {
    var body: some View {
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
}
