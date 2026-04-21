import SwiftUI

@main
struct MinesweeperApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .environmentObject(themeManager)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase != .active {
                        gameViewModel.persistIfNeeded()
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @AppStorage("lastSelectedTab") private var lastSelectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GameView()
                .tabItem {
                    Label("游戏", systemImage: "gamecontroller")
                }
                .tag(0)
            
            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(2)
        }
        .onAppear {
            selectedTab = lastSelectedTab
        }
        .onChange(of: selectedTab) { _, newValue in
            lastSelectedTab = newValue
        }
        .accentColor(.blue)
        .preferredColorScheme(themeManager.appTheme.colorScheme)
    }
}
