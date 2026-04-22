import SwiftUI

struct SettingsPill: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

struct StepperView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        Stepper {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(value)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.gameTheme == .cyber ? Color(red: 0.26, green: 0.66, blue: 0.92) : .primary)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeManager.gameTheme == .cyber ? Color.white.opacity(0.06) : Color(.secondarySystemBackground).opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(themeManager.gameTheme == .cyber ? 0.05 : 0.04), lineWidth: 1)
        )
    }
}

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
