import SwiftUI

struct CellView: View {
    let cell: Cell
    let cellSize: CGFloat
    let isHint: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
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
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.25) {
            onLongPress()
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
    
    private var backgroundColor: Color {
        switch cell.state {
        case .hidden:
            return themeManager.gameTheme.cellHiddenColor
        case .flagged:
            return themeManager.gameTheme.cellFlaggedColor
        case .questioned:
            return Color.purple.opacity(0.2)
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
            return .red
        case .questioned:
            return .purple
        default:
            return .primary
        }
    }
    
    private var shadowColor: Color {
        switch cell.state {
        case .revealed where !cell.isMine && cell.neighborMines > 0:
            return themeManager.colorForNumber(cell.neighborMines).opacity(0.3)
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
