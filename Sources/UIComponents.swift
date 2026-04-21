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
