import MarkdownUI
import SwiftUI

extension Theme {
    static var sengoku: Theme {
        Theme()
            .text {
                ForegroundColor(.shogunIvory)
                FontSize(15)
            }
            .heading1 { config in
                config.label
                    .foregroundStyle(Color.shogunGold)
                    .font(.title.bold())
                    .markdownMargin(top: 16, bottom: 8)
            }
            .heading2 { config in
                config.label
                    .foregroundStyle(Color.shogunGold.opacity(0.85))
                    .font(.title2.bold())
                    .markdownMargin(top: 12, bottom: 6)
            }
            .heading3 { config in
                config.label
                    .foregroundStyle(Color.shogunAccent)
                    .font(.title3.bold())
                    .markdownMargin(top: 8, bottom: 4)
            }
            .strong {
                FontWeight(.bold)
                ForegroundColor(.shogunIvory)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                ForegroundColor(.shogunIvory.opacity(0.8))
            }
            .codeBlock { config in
                config.label
                    .padding(12)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(6)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.shogunIvory.opacity(0.85))
                    .markdownMargin(top: 8, bottom: 8)
            }
            .blockquote { config in
                config.label
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Color.shogunGold.opacity(0.4)
                            .frame(width: 3)
                    }
                    .foregroundStyle(Color.shogunIvory.opacity(0.7))
                    .markdownMargin(top: 4, bottom: 4)
            }
            .link {
                ForegroundColor(.linkGold)
            }
    }
}
