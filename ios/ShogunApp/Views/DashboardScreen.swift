import MarkdownUI
import SwiftUI

struct DashboardScreen: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.shogunBlack.ignoresSafeArea()

                if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(Color.shogunCrimson)
                        Text(error)
                            .foregroundStyle(Color.shogunIvory)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("再試行") {
                            Task { await viewModel.fetch() }
                        }
                        .foregroundStyle(Color.shogunGold)
                    }
                    .padding()
                } else if viewModel.markdownContent.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down")
                            .font(.title2)
                            .foregroundStyle(Color.shogunGold)
                        Text("プルダウンで更新")
                            .foregroundStyle(Color.shogunIvory.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        Markdown(viewModel.markdownContent)
                            .markdownTheme(.sengoku)
                            .padding()
                    }
                    .refreshable {
                        await viewModel.fetch()
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.shogunGold)
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("📊 ダッシュボード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.shogunBlack, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.fetch() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.shogunGold)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            await viewModel.fetch()
        }
    }
}
