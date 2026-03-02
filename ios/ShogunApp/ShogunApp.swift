import SwiftUI

@main
struct ShogunApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlaceholderScreen(title: "将軍")
            }
            .tabItem {
                Image(systemName: "star.fill")
                Text("将軍")
            }
            .tag(0)

            NavigationStack {
                PlaceholderScreen(title: "エージェント")
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("エージェント")
            }
            .tag(1)

            NavigationStack {
                PlaceholderScreen(title: "ダッシュボード")
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

struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        ZStack {
            Color.shogunBlack.ignoresSafeArea()
            Text(title)
                .font(.title)
                .foregroundColor(.shogunIvory)
        }
        .navigationTitle(title)
    }
}
