import SwiftUI

struct CellView: View {
    let cell: Cell
    let cellSize: CGFloat
    let isHint: Bool
    let isScanOverlayVisible: Bool
    let isChainHighlight: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var suppressTap = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: cellSize * 0.15)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cellSize * 0.15)
                        .stroke(themeManager.gameTheme.gridLineColor, lineWidth: 0.5)
                )
            
            // 提示高亮
            if isHint {
                RoundedRectangle(cornerRadius: cellSize * 0.15)
                    .fill(Color.yellow.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: cellSize * 0.15)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
            }
            
            if isScanOverlayVisible && cell.state == .hidden {
                RoundedRectangle(cornerRadius: cellSize * 0.15)
                    .fill(scanOverlayColor)
            }
            
            if isChainHighlight {
                RoundedRectangle(cornerRadius: cellSize * 0.15)
                    .stroke(Color.cyan.opacity(0.9), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: cellSize * 0.15)
                            .fill(Color.cyan.opacity(0.16))
                    )
            }
            
            // 内容
            if !cell.displayText.isEmpty {
                Text(cell.displayText)
                    .font(.system(size: cellSize * 0.55, weight: .bold))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.5)
                    .shadow(color: shadowColor, radius: 0.5, x: 0, y: 0.5)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .scaleEffect(scale)
        .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.08) : nil, value: scale)
        .animation(themeManager.enableAnimations ? .easeInOut(duration: 0.12) : nil, value: isHint)
        .onTapGesture {
            guard !suppressTap else {
                suppressTap = false
                return
            }
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.25) {
            suppressTap = true
            onLongPress()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                suppressTap = false
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    onDoubleTap()
                }
        )
        .pressEvents {
            if themeManager.enableAnimations {
                scale = 0.92
            }
        } onRelease: {
            if themeManager.enableAnimations {
                scale = 1.0
            }
        }
    }
    
    private var scanOverlayColor: Color {
        if cell.isMine {
            return Color.red.opacity(0.18)
        }
        if cell.neighborMines >= 3 {
            return Color.orange.opacity(0.16)
        }
        if cell.neighborMines >= 1 {
            return Color.yellow.opacity(0.12)
        }
        return Color.cyan.opacity(0.08)
    }
    
    private var backgroundColor: Color {
        switch cell.state {
        case .hidden:
            return themeManager.gameTheme.cellHiddenColor
        case .flagged:
            return themeManager.gameTheme.cellFlaggedColor
        case .questioned:
            return themeManager.gameTheme == .graphite ? Color(red: 0.42, green: 0.35, blue: 0.72).opacity(0.28) : (themeManager.gameTheme == .cyber ? Color(red: 0.62, green: 0.26, blue: 1.0).opacity(0.3) : Color.purple.opacity(0.2))
        case .exploded:
            return themeManager.gameTheme.cellExplodedColor
        case .revealed:
            if cell.isMine {
                return themeManager.gameTheme.cellExplodedColor
            } else {
                return themeManager.gameTheme.cellRevealedColor
            }
        }
    }
    
    private var textColor: Color {
        switch cell.state {
        case .revealed where !cell.isMine && cell.neighborMines > 0:
            return themeManager.colorForNumber(cell.neighborMines)
        case .flagged:
            return themeManager.gameTheme == .graphite ? Color(red: 0.89, green: 0.28, blue: 0.24) : (themeManager.gameTheme == .cyber ? Color(red: 1.0, green: 0.28, blue: 0.60) : .red)
        case .questioned:
            return themeManager.gameTheme == .graphite ? Color(red: 0.70, green: 0.62, blue: 0.98) : (themeManager.gameTheme == .cyber ? Color(red: 0.70, green: 0.48, blue: 1.0) : .purple)
        default:
            return themeManager.gameTheme == .graphite ? Color.white.opacity(0.92) : (themeManager.gameTheme == .cyber ? Color(red: 0.05, green: 0.12, blue: 0.18) : .primary)
        }
    }
    
    private var shadowColor: Color {
        switch cell.state {
        case .revealed where !cell.isMine && cell.neighborMines > 0:
            return themeManager.colorForNumber(cell.neighborMines).opacity(themeManager.gameTheme == .graphite ? 0.18 : 0.3)
        default:
            return .clear
        }
    }
}

// MARK: - 按下事件扩展
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}
