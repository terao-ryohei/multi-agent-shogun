import SwiftUI

@main
struct ShogunApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var sshService = SSHService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sshService)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                Task {
                    if !sshService.isConnected {
                        try? await sshService.reconnect()
                    }
                }
            case .background:
                break
            default:
                break
            }
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ShogunScreen()
            }
            .tabItem {
                Image(systemName: "star.fill")
                Text("将軍")
            }
            .tag(0)

            NavigationStack {
                AgentsScreen()
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("エージェント")
            }
            .tag(1)

            NavigationStack {
                DashboardScreen()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("ダッシュボード")
            }
            .tag(2)

            NavigationStack {
                SettingsScreen()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("設定")
            }
            .tag(3)
        }
        .tint(.shogunGold)
        .preferredColorScheme(.dark)
    }
}
