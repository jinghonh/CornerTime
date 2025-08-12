//
//  ClockView.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 时钟显示视图
struct ClockView: View {
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 主时钟显示
            HStack(spacing: 0) {
                Text(viewModel.currentTime)
                    .font(clockFont)
                    .foregroundColor(clockColor)
                    .opacity(clockOpacity)
                    .padding(clockPadding)
            }
            .background(clockBackground)
            .cornerRadius(clockCornerRadius)
            .shadow(
                color: viewModel.preferencesManager.appearanceConfig.enableShadow ? .black.opacity(0.1) : .clear,
                radius: viewModel.preferencesManager.appearanceConfig.shadowRadius,
                x: 0,
                y: 1
            )
            .onTapGesture {
                if !viewModel.allowsClickThrough {
                    handleClockTap()
                }
            }
            .contextMenu {
                clockContextMenu
            }
            
            // 锁定状态指示器
            if viewModel.isLocked || viewModel.allowsClickThrough {
                LockIndicator(
                    isLocked: viewModel.isLocked,
                    allowsClickThrough: viewModel.allowsClickThrough
                )
                .offset(x: 5, y: -5)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var clockFont: Font {
        let config = viewModel.preferencesManager.appearanceConfig
        
        let design: Font.Design = {
            switch config.fontDesign {
            case .default: return .default
            case .monospaced: return .monospaced
            case .rounded: return .rounded
            case .serif: return .serif
            }
        }()
        
        let weight: Font.Weight = {
            switch config.fontWeight {
            case .ultraLight: return .ultraLight
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            }
        }()
        
        return .system(size: config.fontSize, weight: weight, design: design)
    }
    
    private var clockColor: Color {
        // 根据系统外观自动调整颜色
        Color.primary
    }
    
    private var clockOpacity: Double {
        viewModel.preferencesManager.appearanceConfig.opacity
    }
    
    private var clockPadding: EdgeInsets {
        EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    }
    
    private var clockBackground: some View {
        Group {
            if viewModel.preferencesManager.appearanceConfig.useBlurBackground {
                // 毛玻璃背景
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            } else {
                // 透明背景
                Color.clear
            }
        }
    }
    
    private var clockCornerRadius: CGFloat {
        viewModel.preferencesManager.appearanceConfig.cornerRadius
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var clockContextMenu: some View {
        Group {
            Button("显示/隐藏") {
                viewModel.toggleVisibility()
            }
            .keyboardShortcut(.space, modifiers: [.command, .control])
            
            Divider()
            
            Button(viewModel.isLocked ? "🔓 解锁位置" : "🔒 锁定位置") {
                viewModel.togglePositionLock()
            }
            .keyboardShortcut("l", modifiers: [.command, .control])
            
            Button(viewModel.allowsClickThrough ? "🚫 禁用点击穿透" : "👆 启用点击穿透") {
                viewModel.toggleClickThrough()
            }
            .keyboardShortcut("t", modifiers: [.command, .control])
            
            Divider()
            
            Menu("位置") {
                ForEach(WindowPosition.allCases, id: \.self) { position in
                    Button(position.displayName) {
                        viewModel.updateWindowPosition(position)
                    }
                }
                Divider()
                Button("重置位置") { viewModel.resetToDefaultPosition() }
            }
            
            Menu("窗口设置") {
                Button(viewModel.windowManager.windowConfig.enableDragging ? "禁用拖拽" : "启用拖拽") {
                    viewModel.updateDragSettings(
                        enableDragging: !viewModel.windowManager.windowConfig.enableDragging,
                        enableSnapping: viewModel.windowManager.windowConfig.enableSnapping,
                        snapDistance: viewModel.windowManager.windowConfig.snapDistance
                    )
                }
                
                Button(viewModel.windowManager.windowConfig.enableSnapping ? "禁用磁性吸附" : "启用磁性吸附") {
                    viewModel.updateDragSettings(
                        enableDragging: viewModel.windowManager.windowConfig.enableDragging,
                        enableSnapping: !viewModel.windowManager.windowConfig.enableSnapping,
                        snapDistance: viewModel.windowManager.windowConfig.snapDistance
                    )
                }
                
                Button(viewModel.windowManager.windowConfig.rememberPosition ? "禁用位置记忆" : "启用位置记忆") {
                    viewModel.updatePositionMemory(enabled: !viewModel.windowManager.windowConfig.rememberPosition)
                }
            }
            
            Menu("时间格式") {
                Button(viewModel.preferencesManager.timeFormat.is24Hour ? "切换到12小时制" : "切换到24小时制") {
                    viewModel.toggle24HourFormat()
                }
                .keyboardShortcut("h", modifiers: [.command])
                
                Button(viewModel.preferencesManager.timeFormat.showSeconds ? "隐藏秒" : "显示秒") {
                    viewModel.toggleSecondsDisplay()
                }
                .keyboardShortcut("s", modifiers: [.command])
                
                Divider()
                
                ForEach(DateFormatOption.allCases, id: \.self) { option in
                    Button(option.displayName) {
                        viewModel.updateDateFormat(option)
                    }
                    .disabled(option == viewModel.preferencesManager.timeFormat.dateFormat)
                }
            }
            
            Menu("外观设置") {
                Menu("字体大小") {
                    ForEach(viewModel.getFontSizePresets(), id: \.self) { size in
                        Button("\(Int(size))pt") {
                            viewModel.updateFontSize(size)
                        }
                        .disabled(size == viewModel.preferencesManager.appearanceConfig.fontSize)
                    }
                }
                
                Menu("字体粗细") {
                    ForEach(FontWeightOption.allCases, id: \.self) { weight in
                        Button(weight.displayName) {
                            viewModel.updateFontWeight(weight)
                        }
                        .disabled(weight == viewModel.preferencesManager.appearanceConfig.fontWeight)
                    }
                }
                
                Menu("字体设计") {
                    ForEach(FontDesignOption.allCases, id: \.self) { design in
                        Button(design.displayName) {
                            viewModel.updateFontDesign(design)
                        }
                        .disabled(design == viewModel.preferencesManager.appearanceConfig.fontDesign)
                    }
                }
                
                Divider()
                
                Button(viewModel.preferencesManager.appearanceConfig.enableShadow ? "禁用阴影" : "启用阴影") {
                    viewModel.toggleShadow()
                }
                
                Menu("透明度") {
                    ForEach([0.3, 0.5, 0.7, 0.8, 0.9, 1.0], id: \.self) { opacity in
                        Button("\(Int(opacity * 100))%") {
                            viewModel.updateOpacity(opacity)
                        }
                        .disabled(abs(opacity - viewModel.preferencesManager.appearanceConfig.opacity) < 0.01)
                    }
                }
            }
            
            Divider()
            
            // 状态显示
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.getLockStatusDescription())
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(viewModel.getAppearanceDescription())
                    .foregroundColor(.secondary)
                    .font(.caption2)
            }
            
            Divider()
            
            AppearanceButton(viewModel: viewModel)
            
            Button("设置...") {
                viewModel.showSettings()
            }
            
            Button("退出") {
                viewModel.quitApplication()
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }
    
    // MARK: - Private Methods
    
    private func handleClockTap() {
        // 非穿透模式下的点击处理
        // 可以在这里添加其他交互功能
        print("时钟被点击")
    }
}

/// 毛玻璃效果视图
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    init(material: NSVisualEffectView.Material = .hudWindow,
         blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

#Preview {
    ClockView(viewModel: ClockViewModel())
        .frame(width: 200, height: 60)
}