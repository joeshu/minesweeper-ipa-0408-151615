import SwiftUI

struct SurfaceCardModifier: ViewModifier {
    var radius: CGFloat = 18
    var fillColor: Color = Color(.secondarySystemBackground).opacity(0.96)
    var strokeOpacity: Double = 0.06
    var shadowOpacity: Double = 0.06
    var shadowRadius: CGFloat = 14
    var shadowY: CGFloat = 6
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.primary.opacity(strokeOpacity), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
            )
    }
}

extension GameTheme {
    var pageTopTint: Color {
        switch self {
        case .cyber:
            return Color(red: 0.82, green: 0.92, blue: 1.0)
        default:
            return boardBackgroundColor.opacity(0.24)
        }
    }
    
    var pageBottomTint: Color {
        switch self {
        case .cyber:
            return Color(red: 0.93, green: 0.97, blue: 1.0)
        default:
            return Color(.systemBackground)
        }
    }
    
    var pageCardFill: Color {
        switch self {
        case .cyber:
            return Color.white.opacity(0.10)
        default:
            return Color(.secondarySystemBackground).opacity(0.90)
        }
    }
    
    var pageInnerCardFill: Color {
        switch self {
        case .cyber:
            return Color.white.opacity(0.06)
        default:
            return Color(.secondarySystemBackground).opacity(0.84)
        }
    }
    
    var pageCardStrokeOpacity: Double {
        switch self {
        case .cyber:
            return 0.05
        default:
            return 0.04
        }
    }
}

extension View {
    func surfaceCard(
        radius: CGFloat = 18,
        fillColor: Color = Color(.secondarySystemBackground).opacity(0.96),
        strokeOpacity: Double = 0.06,
        shadowOpacity: Double = 0.06,
        shadowRadius: CGFloat = 14,
        shadowY: CGFloat = 6
    ) -> some View {
        modifier(
            SurfaceCardModifier(
                radius: radius,
                fillColor: fillColor,
                strokeOpacity: strokeOpacity,
                shadowOpacity: shadowOpacity,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }
}

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
