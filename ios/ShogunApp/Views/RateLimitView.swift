import SwiftUI

struct RateLimitView: View {
    let info: RateLimitInfo?

    var body: some View {
        HStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * (info?.percentage ?? 0))
                }
            }
            .frame(height: 8)
            Text(info?.label ?? "--")
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private var barColor: Color {
        switch info?.level {
        case .green: return Color.shogunGreen
        case .yellow: return .yellow
        case .red: return Color.shogunCrimson
        default: return .gray
        }
    }
}
