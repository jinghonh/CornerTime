//
//  ContextMenuBuilder.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 上下文菜单构建器，用于创建分组和组织化的菜单
@MainActor
struct ContextMenuBuilder {
    let viewModel: ClockViewModel
    
    // MARK: - 主菜单构建器
    
    @ViewBuilder
    func buildMainContextMenu() -> some View {
        Group {
            // 核心功能组
            basicControlsGroup
            
            Divider()
            
            // 位置和行为组
            positionAndBehaviorGroup
            
            Divider()
            
            // 外观设置组
            appearanceGroup
            
            Divider()
            
            // 状态信息和设置
            statusAndSettingsGroup
        }
    }
    
    // MARK: - 菜单组
    
    @ViewBuilder
    private var basicControlsGroup: some View {
        Group {
            Button("显示/隐藏") {
                viewModel.toggleVisibility()
            }
            .keyboardShortcut(.space, modifiers: [.command, .control])
            
            Button(viewModel.isLocked ? "🔓 解锁位置" : "🔒 锁定位置") {
                viewModel.togglePositionLock()
            }
            .keyboardShortcut("l", modifiers: [.command, .control])
            
            Button(viewModel.allowsClickThrough ? "🚫 禁用点击穿透" : "👆 启用点击穿透") {
                viewModel.toggleClickThrough()
            }
            .keyboardShortcut("t", modifiers: [.command, .control])
        }
    }
    
    @ViewBuilder
    private var positionAndBehaviorGroup: some View {
        Group {
            Menu("位置设置") {
                ForEach(WindowPosition.allCases, id: \.self) { position in
                    Button(position.displayName) {
                        viewModel.updateWindowPosition(position)
                    }
                }
                Divider()
                Button("重置位置") { viewModel.resetToDefaultPosition() }
            }
            
            Menu("窗口行为") {
                Toggle("启用拖拽", isOn: Binding(
                    get: { viewModel.windowManager.windowConfig.enableDragging },
                    set: { enabled in
                        viewModel.updateDragSettings(
                            enableDragging: enabled,
                            enableSnapping: viewModel.windowManager.windowConfig.enableSnapping,
                            snapDistance: viewModel.windowManager.windowConfig.snapDistance
                        )
                    }
                ))
                
                Toggle("磁性吸附", isOn: Binding(
                    get: { viewModel.windowManager.windowConfig.enableSnapping },
                    set: { enabled in
                        viewModel.updateDragSettings(
                            enableDragging: viewModel.windowManager.windowConfig.enableDragging,
                            enableSnapping: enabled,
                            snapDistance: viewModel.windowManager.windowConfig.snapDistance
                        )
                    }
                ))
                
                Toggle("位置记忆", isOn: Binding(
                    get: { viewModel.windowManager.windowConfig.rememberPosition },
                    set: { enabled in
                        viewModel.updatePositionMemory(enabled: enabled)
                    }
                ))
            }
        }
    }
    
    @ViewBuilder
    private var appearanceGroup: some View {
        Group {
            Menu("时间格式") {
                Button(viewModel.preferencesManager.timeFormat.is24Hour ? "切换到12小时制" : "切换到24小时制") {
                    viewModel.toggle24HourFormat()
                }
                .keyboardShortcut("h", modifiers: [.command])
                
                Toggle("显示秒", isOn: Binding(
                    get: { viewModel.preferencesManager.timeFormat.showSeconds },
                    set: { _ in viewModel.toggleSecondsDisplay() }
                ))
                .keyboardShortcut("s", modifiers: [.command])
                
                Divider()
                
                Menu("日期格式") {
                    ForEach(DateFormatOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            viewModel.updateDateFormat(option)
                        }
                        .disabled(option == viewModel.preferencesManager.timeFormat.dateFormat)
                    }
                }
            }
            
            Menu("字体和外观") {
                Menu("字体大小") {
                    ForEach([12, 16, 20, 24, 28, 32, 36, 42, 48], id: \.self) { size in
                        Button("\(Int(size))pt") {
                            viewModel.updateFontSize(CGFloat(size))
                        }
                        .disabled(CGFloat(size) == viewModel.preferencesManager.appearanceConfig.fontSize)
                    }
                }
                
                Menu("透明度") {
                    ForEach([0.5, 0.7, 0.8, 0.9, 1.0], id: \.self) { opacity in
                        Button("\(Int(opacity * 100))%") {
                            viewModel.updateOpacity(opacity)
                        }
                        .disabled(abs(opacity - viewModel.preferencesManager.appearanceConfig.opacity) < 0.01)
                    }
                }
                
                Toggle("阴影效果", isOn: Binding(
                    get: { viewModel.preferencesManager.appearanceConfig.enableShadow },
                    set: { _ in viewModel.toggleShadow() }
                ))
            }
        }
    }
    
    @ViewBuilder
    private var statusAndSettingsGroup: some View {
        Group {
            // 紧凑的状态信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("状态:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.getLockStatusDescription())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
            
            AppearanceButton(viewModel: viewModel)
            
            Button("设置...") {
                viewModel.showSettings()
            }
            .keyboardShortcut(",", modifiers: [.command])
            
            Divider()
            
            Button("退出") {
                viewModel.quitApplication()
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }
}

/// 菜单项常量
private struct MenuConstants {
    static let commonFontSizes: [CGFloat] = [12, 16, 20, 24, 28, 32, 36, 42, 48]
    static let commonOpacities: [Double] = [0.5, 0.7, 0.8, 0.9, 1.0]
}