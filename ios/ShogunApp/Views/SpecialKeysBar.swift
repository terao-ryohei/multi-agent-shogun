import SwiftUI

struct SpecialKeysBar: View {
    @ObservedObject var viewModel: ShogunViewModel

    let keys: [(label: String, key: SpecialKey)] = [
        ("↩", .enter), ("C-c", .ctrlC), ("C-b", .ctrlB),
        ("↑", .arrowUp), ("↓", .arrowDown), ("←", .arrowLeft), ("→", .arrowRight),
        ("Tab", .tab), ("ESC", .escape), ("C-o", .ctrlO), ("C-d", .ctrlD)
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(keys, id: \.label) { item in
                    Button(item.label) {
                        Task { await viewModel.sendKey(item.key) }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(Color.shogunIvory)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.shogunGold, lineWidth: 1))
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .background(Color.shogunBlack.opacity(0.8))
    }
}
