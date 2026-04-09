import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showResetConfirmation = false
    @State private var showClearStatsConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // 难度设置
                Section(header: Text("游戏难度")) {
                    Picker("难度", selection: Binding(
                        get: { viewModel.difficulty },
                        set: { viewModel.setDifficulty($0) }
                    )) {
                        ForEach(Difficulty.allCases) { difficulty in
                            Text(difficulty.rawValue)
                                .tag(difficulty)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(viewModel.difficulty.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 自定义设置
                if viewModel.difficulty == .custom {
                    Section(header: Text("自定义设置")) {
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
                
                // 挑战模式
                Section(header: Text("挑战模式")) {
                    HStack {
                        Text("每日挑战")
                        Spacer()
                        if viewModel.gameStats.getTodayDailyChallengeStatus() != nil {
                            Label("今日已完成", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Picker("模式", selection: Binding(
                        get: { viewModel.challengeMode },
                        set: { viewModel.setChallengeMode($0) }
                    )) {
                        ForEach(ChallengeMode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    
                    Text(viewModel.challengeMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 外观设置
                Section(header: Text("外观")) {
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
                
                // 声音设置
                Section(header: Text("声音")) {
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
                
                // 触觉反馈设置
                Section(header: Text("触觉反馈")) {
                    Toggle("启用触觉反馈", isOn: Binding(
                        get: { viewModel.hapticManager.isHapticEnabled },
                        set: { _ in viewModel.hapticManager.toggleHaptic() }
                    ))
                }
                
                // 游戏统计
                Section(header: Text("游戏统计")) {
                    StatRow(title: "总游戏数", value: "\(viewModel.gameStats.totalGames)")
                    StatRow(title: "胜利次数", value: "\(viewModel.gameStats.wins)", valueColor: .green)
                    StatRow(title: "失败次数", value: "\(viewModel.gameStats.losses)", valueColor: .red)
                    StatRow(title: "胜率", value: String(format: "%.1f%%", viewModel.gameStats.getWinRate()))
                    
                    Button(role: .destructive) {
                        showClearStatsConfirmation = true
                    } label: {
                        Label("清除所有记录", systemImage: "trash")
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
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
            .navigationTitle("设置")
            .alert("确认清除", isPresented: $showClearStatsConfirmation) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    viewModel.gameStats.clearAllRecords()
                }
            } message: {
                Text("确定要清除所有游戏记录吗？此操作无法撤销。")
            }
        }
    }
}

// MARK: - StepperView
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
