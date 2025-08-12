//
//  SettingsWindow.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 主设置窗口
struct SettingsWindow: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var selectedTab: SettingsTab = .appearance
    
    var body: some View {
        NavigationView {
            // 侧边栏
            List(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack {
                        Image(systemName: tab.iconName)
                        Text(tab.displayName)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(selectedTab == tab ? .accentColor : .primary)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)
            
            // 主内容区
            Group {
                switch selectedTab {
                case .appearance:
                    AppearanceSettingsView(viewModel: viewModel)
                case .behavior:
                    BehaviorSettingsView(viewModel: viewModel)
                case .position:
                    PositionSettingsView(viewModel: viewModel)
                case .advanced:
                    AdvancedSettingsView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 400, minHeight: 300)
        }
        .frame(width: 600, height: 500)
        .navigationTitle("CornerTime 设置")
    }
}

/// 设置标签页
enum SettingsTab: String, CaseIterable {
    case appearance = "appearance"
    case behavior = "behavior"
    case position = "position"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .appearance: return "外观"
        case .behavior: return "行为"
        case .position: return "位置"
        case .advanced: return "高级"
        }
    }
    
    var iconName: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .behavior: return "gearshape.fill"
        case .position: return "location.fill"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

/// 外观设置视图
struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("外观设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // 使用现有的外观面板组件
                AppearancePanel(viewModel: viewModel)
            }
            .padding()
        }
    }
}

/// 行为设置视图
struct BehaviorSettingsView: View {
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("行为设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                GroupBox("启动和显示") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("开机启动", isOn: Binding(
                            get: { viewModel.preferencesManager.behaviorConfig.launchAtLogin },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.behaviorConfig
                                let newConfig = ConfigurationHelper.updateBehaviorConfig(
                                    currentConfig,
                                    launchAtLogin: value
                                )
                                viewModel.preferencesManager.behaviorConfig = newConfig
                            }
                        ))
                        
                        Toggle("隐藏Dock图标", isOn: Binding(
                            get: { viewModel.preferencesManager.behaviorConfig.hideFromDock },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.behaviorConfig
                                let newConfig = ConfigurationHelper.updateBehaviorConfig(
                                    currentConfig,
                                    hideFromDock: value
                                )
                                viewModel.preferencesManager.behaviorConfig = newConfig
                            }
                        ))
                        
                        Toggle("在截图/录屏中隐藏", isOn: Binding(
                            get: { viewModel.preferencesManager.behaviorConfig.hideFromScreenshots },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.behaviorConfig
                                let newConfig = ConfigurationHelper.updateBehaviorConfig(
                                    currentConfig,
                                    hideFromScreenshots: value
                                )
                                viewModel.preferencesManager.behaviorConfig = newConfig
                            }
                        ))
                    }
                }
                
                GroupBox("全屏和空间") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("在全屏应用中显示", isOn: Binding(
                            get: { viewModel.preferencesManager.behaviorConfig.showInFullScreen },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.behaviorConfig
                                let newConfig = ConfigurationHelper.updateBehaviorConfig(
                                    currentConfig,
                                    showInFullScreen: value
                                )
                                viewModel.preferencesManager.behaviorConfig = newConfig
                            }
                        ))
                        
                        Toggle("在所有空间中显示", isOn: Binding(
                            get: { viewModel.preferencesManager.behaviorConfig.showInAllSpaces },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.behaviorConfig
                                let newConfig = ConfigurationHelper.updateBehaviorConfig(
                                    currentConfig,
                                    showInAllSpaces: value
                                )
                                viewModel.preferencesManager.behaviorConfig = newConfig
                            }
                        ))
                    }
                }
            }
            .padding()
        }
    }
}

/// 位置设置视图
struct PositionSettingsView: View {
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("位置设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                GroupBox("窗口位置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("预设位置", selection: Binding(
                            get: { viewModel.preferencesManager.windowConfig.position },
                            set: { position in
                                viewModel.updateWindowPosition(position)
                            }
                        )) {
                            ForEach(WindowPosition.allCases, id: \.self) { position in
                                Text(position.displayName).tag(position)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Button("重置位置") {
                                viewModel.resetToDefaultPosition()
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                    }
                }
                
                GroupBox("拖拽设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("启用拖拽", isOn: Binding(
                            get: { viewModel.preferencesManager.windowConfig.enableDragging },
                            set: { value in
                                viewModel.updateDragSettings(
                                    enableDragging: value,
                                    enableSnapping: viewModel.preferencesManager.windowConfig.enableSnapping,
                                    snapDistance: viewModel.preferencesManager.windowConfig.snapDistance
                                )
                            }
                        ))
                        
                        Toggle("磁性吸附", isOn: Binding(
                            get: { viewModel.preferencesManager.windowConfig.enableSnapping },
                            set: { value in
                                viewModel.updateDragSettings(
                                    enableDragging: viewModel.preferencesManager.windowConfig.enableDragging,
                                    enableSnapping: value,
                                    snapDistance: viewModel.preferencesManager.windowConfig.snapDistance
                                )
                            }
                        ))
                        
                        Toggle("位置记忆", isOn: Binding(
                            get: { viewModel.preferencesManager.windowConfig.rememberPosition },
                            set: { value in
                                viewModel.updatePositionMemory(enabled: value)
                            }
                        ))
                        
                        Toggle("尊重安全区域", isOn: Binding(
                            get: { viewModel.preferencesManager.windowConfig.respectSafeArea },
                            set: { value in
                                viewModel.updateSafeAreaSettings(respectSafeArea: value)
                            }
                        ))
                    }
                }
            }
            .padding()
        }
    }
}

/// 高级设置视图
struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("高级设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                GroupBox("调试和日志") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("启用调试模式", isOn: Binding(
                            get: { viewModel.preferencesManager.advancedConfig.enableDebugMode },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.advancedConfig
                                let newConfig = ConfigurationHelper.updateAdvancedConfig(
                                    currentConfig,
                                    enableDebugMode: value
                                )
                                viewModel.preferencesManager.advancedConfig = newConfig
                            }
                        ))
                        
                        Toggle("启用日志记录", isOn: Binding(
                            get: { viewModel.preferencesManager.advancedConfig.enableLogging },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.advancedConfig
                                let newConfig = ConfigurationHelper.updateAdvancedConfig(
                                    currentConfig,
                                    enableLogging: value
                                )
                                viewModel.preferencesManager.advancedConfig = newConfig
                            }
                        ))
                    }
                }
                
                GroupBox("性能") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("节能模式", isOn: Binding(
                            get: { viewModel.preferencesManager.advancedConfig.energySaveMode },
                            set: { value in
                                let currentConfig = viewModel.preferencesManager.advancedConfig
                                let newConfig = ConfigurationHelper.updateAdvancedConfig(
                                    currentConfig,
                                    energySaveMode: value
                                )
                                viewModel.preferencesManager.advancedConfig = newConfig
                            }
                        ))
                    }
                }
                
                GroupBox("配置管理") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("导出配置") {
                                exportConfiguration()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("导入配置") {
                                importConfiguration()
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Button("重置所有设置") {
                                viewModel.preferencesManager.resetToDefaults()
                            }
                            .buttonStyle(.borderedProminent)
                            .foregroundColor(.red)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func exportConfiguration() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "CornerTime配置.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let data = viewModel.preferencesManager.exportConfiguration() {
                do {
                    try data.write(to: url)
                    print("配置导出成功")
                } catch {
                    print("配置导出失败: \(error)")
                }
            }
        }
    }
    
    private func importConfiguration() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let data = try Data(contentsOf: url)
                if viewModel.preferencesManager.importConfiguration(from: data) {
                    print("配置导入成功")
                } else {
                    print("配置导入失败")
                }
            } catch {
                print("读取配置文件失败: \(error)")
            }
        }
    }
}

#Preview {
    SettingsWindow(viewModel: ClockViewModel())
}