//
//  MultiDisplayPanel.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 多显示器设置面板
struct MultiDisplayPanel: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var selectedMode: MultiDisplayMode = .mainDisplayOnly
    @State private var selectedDisplays: Set<String> = Set()
    @State private var syncConfigurations = true
    @State private var autoDetectNew = true
    @State private var rememberPreferences = true
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "tv.and.hifispeaker.fill")
                    .foregroundColor(.blue)
                Text("多显示器设置")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // 显示器模式选择
                    displayModeSection
                    
                    Divider()
                    
                    // 显示器列表（仅在选定显示器模式下显示）
                    if selectedMode == .selectedDisplays {
                        displaySelectionSection
                        Divider()
                    }
                    
                    // 高级选项
                    advancedOptionsSection
                    
                    Divider()
                    
                    // 显示器信息
                    displayInfoSection
                    
                    Divider()
                    
                    // 操作按钮
                    actionButtonsSection
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("显示模式")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                ForEach(MultiDisplayMode.allCases, id: \.self) { mode in
                    DisplayModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onSelect: { selectedMode = mode }
                    )
                }
            }
        }
    }
    
    private var displaySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择显示器")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if viewModel.displayManager.displays.isEmpty {
                Text("未检测到显示器")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(viewModel.displayManager.displays, id: \.uuid) { display in
                        DisplayCard(
                            display: display,
                            isSelected: selectedDisplays.contains(display.uuid),
                            onToggle: { toggleDisplaySelection(display.uuid) }
                        )
                    }
                }
            }
        }
    }
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级选项")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Toggle("同步配置到所有显示器", isOn: $syncConfigurations)
                    .help("在所有显示器上使用相同的外观和时间格式配置")
                
                Toggle("自动检测新显示器", isOn: $autoDetectNew)
                    .help("当连接新显示器时自动显示时钟")
                
                Toggle("记住显示器偏好", isOn: $rememberPreferences)
                    .help("保存每个显示器的个性化设置")
            }
        }
    }
    
    private var displayInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            let statistics = viewModel.multiDisplayManager?.getDisplayStatistics()
            
            VStack(alignment: .leading, spacing: 6) {
                InfoRow(title: "连接的显示器", value: "\(viewModel.displayManager.displays.count)")
                InfoRow(title: "活动窗口", value: "\(statistics?.activeWindows ?? 0)")
                InfoRow(title: "当前模式", value: statistics?.currentMode.displayName ?? "未知")
                InfoRow(title: "多显示器状态", value: (statistics?.isEnabled ?? false) ? "启用" : "禁用")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button("应用设置") {
                applySettings()
            }
            .buttonStyle(.borderedProminent)
            
            Button("重置") {
                resetToDefaults()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("刷新显示器") {
                viewModel.displayManager.updateDisplays()
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        let config = viewModel.preferencesManager.displayConfig
        selectedMode = config.multiDisplayMode
        selectedDisplays = config.enabledDisplayUUIDs
        syncConfigurations = config.syncConfigurationAcrossDisplays
        autoDetectNew = config.autoDetectNewDisplays
        rememberPreferences = config.rememberDisplayPreferences
    }
    
    private func toggleDisplaySelection(_ displayUUID: String) {
        if selectedDisplays.contains(displayUUID) {
            selectedDisplays.remove(displayUUID)
        } else {
            selectedDisplays.insert(displayUUID)
        }
    }
    
    private func applySettings() {
        let config = viewModel.preferencesManager.displayConfig
        let newConfig = DisplayConfig(
            targetDisplayUUID: config.targetDisplayUUID,
            showOnAllDisplays: selectedMode == .allDisplays,
            followMainDisplay: selectedMode == .mainDisplayOnly,
            multiDisplayMode: selectedMode,
            enabledDisplayUUIDs: selectedDisplays,
            perDisplayConfigurations: config.perDisplayConfigurations,
            syncConfigurationAcrossDisplays: syncConfigurations,
            autoDetectNewDisplays: autoDetectNew,
            rememberDisplayPreferences: rememberPreferences
        )
        
        viewModel.preferencesManager.displayConfig = newConfig
        
        // 应用多显示器模式
        if let multiDisplayManager = viewModel.multiDisplayManager {
            if selectedMode != .singleDisplay {
                multiDisplayManager.enableMultiDisplay(mode: selectedMode)
            } else {
                multiDisplayManager.disableMultiDisplay()
            }
        }
        
        print("🖥️ 多显示器设置已应用")
    }
    
    private func resetToDefaults() {
        selectedMode = .mainDisplayOnly
        selectedDisplays.removeAll()
        syncConfigurations = true
        autoDetectNew = true
        rememberPreferences = true
    }
}

/// 显示模式卡片
struct DisplayModeCard: View {
    let mode: MultiDisplayMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: modeIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modeIcon: String {
        switch mode {
        case .singleDisplay: return "tv"
        case .mainDisplayOnly: return "tv.fill"
        case .allDisplays: return "tv.and.hifispeaker.fill"
        case .selectedDisplays: return "tv.and.mediabox"
        case .followCursor: return "cursorarrow.and.square.on.square.dashed"
        }
    }
}

/// 显示器卡片
struct DisplayCard: View {
    let display: DisplayInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: display.isMain ? "tv.fill" : "tv")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(display.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                    
                    Text("\(Int(display.frame.width)) × \(Int(display.frame.height))")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    if display.isMain {
                        Text("主显示器")
                            .font(.caption)
                            .foregroundColor(isSelected ? .yellow : .orange)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 信息行
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

/// 多显示器设置按钮
struct MultiDisplayButton: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var showingPanel = false
    
    var body: some View {
        Button("多显示器设置...") {
            showingPanel = true
        }
        .popover(isPresented: $showingPanel) {
            MultiDisplayPanel(viewModel: viewModel)
        }
    }
}

#Preview {
    MultiDisplayPanel(viewModel: ClockViewModel())
        .padding()
}