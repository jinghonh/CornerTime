//
//  MultiDisplayManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import Foundation
import Combine

/// 显示器窗口信息
struct DisplayWindow {
    let displayUUID: String
    let window: NSWindow
    let controller: ClockWindowController
    let viewModel: ClockViewModel
    
    init(displayUUID: String, window: NSWindow, controller: ClockWindowController, viewModel: ClockViewModel) {
        self.displayUUID = displayUUID
        self.window = window
        self.controller = controller
        self.viewModel = viewModel
    }
}

/// 多显示器管理器
@MainActor
class MultiDisplayManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isMultiDisplayEnabled: Bool = false
    @Published var activeDisplayWindows: [String: DisplayWindow] = [:]
    @Published var currentMode: MultiDisplayMode = .mainDisplayOnly
    
    // MARK: - Private Properties
    private let displayManager: DisplayManager
    private let preferencesManager: PreferencesManager
    private var cancellables = Set<AnyCancellable>()
    private var cursorTrackingTimer: Timer?
    private var lastCursorDisplayUUID: String?
    
    // MARK: - Initialization
    init(displayManager: DisplayManager, preferencesManager: PreferencesManager) {
        self.displayManager = displayManager
        self.preferencesManager = preferencesManager
        
        setupObservers()
        updateDisplayConfiguration()
    }
    
    deinit {
        cursorTrackingTimer?.invalidate()
        Task { @MainActor in
            self.cleanupAllWindows()
        }
    }
    
    // MARK: - Public Methods
    
    /// 启用多显示器模式
    func enableMultiDisplay(mode: MultiDisplayMode) {
        currentMode = mode
        isMultiDisplayEnabled = true
        
        var newConfig = preferencesManager.displayConfig
        newConfig = DisplayConfig(
            targetDisplayUUID: newConfig.targetDisplayUUID,
            showOnAllDisplays: mode == .allDisplays,
            followMainDisplay: mode == .mainDisplayOnly,
            multiDisplayMode: mode,
            enabledDisplayUUIDs: newConfig.enabledDisplayUUIDs,
            perDisplayConfigurations: newConfig.perDisplayConfigurations,
            syncConfigurationAcrossDisplays: newConfig.syncConfigurationAcrossDisplays,
            autoDetectNewDisplays: newConfig.autoDetectNewDisplays,
            rememberDisplayPreferences: newConfig.rememberDisplayPreferences
        )
        preferencesManager.displayConfig = newConfig
        
        updateDisplayWindows()
        
        print("🖥️ 多显示器模式已启用: \(mode.displayName)")
    }
    
    /// 禁用多显示器模式
    func disableMultiDisplay() {
        isMultiDisplayEnabled = false
        currentMode = .singleDisplay
        cleanupAllWindows()
        
        print("🖥️ 多显示器模式已禁用")
    }
    
    /// 为指定显示器启用/禁用时钟
    func setDisplayEnabled(_ displayUUID: String, enabled: Bool) {
        let config = preferencesManager.displayConfig
        var enabledUUIDs = config.enabledDisplayUUIDs
        
        if enabled {
            enabledUUIDs.insert(displayUUID)
        } else {
            enabledUUIDs.remove(displayUUID)
        }
        
        let newConfig = DisplayConfig(
            targetDisplayUUID: config.targetDisplayUUID,
            showOnAllDisplays: config.showOnAllDisplays,
            followMainDisplay: config.followMainDisplay,
            multiDisplayMode: config.multiDisplayMode,
            enabledDisplayUUIDs: enabledUUIDs,
            perDisplayConfigurations: config.perDisplayConfigurations,
            syncConfigurationAcrossDisplays: config.syncConfigurationAcrossDisplays,
            autoDetectNewDisplays: config.autoDetectNewDisplays,
            rememberDisplayPreferences: config.rememberDisplayPreferences
        )
        preferencesManager.displayConfig = newConfig
        
        updateDisplayWindows()
        
        print("🖥️ 显示器 \(displayUUID) \(enabled ? "启用" : "禁用")")
    }
    
    /// 为指定显示器设置专属配置
    func setPerDisplayConfig(_ displayUUID: String, config: PerDisplayConfig) {
        let displayConfig = preferencesManager.displayConfig
        var perDisplayConfigs = displayConfig.perDisplayConfigurations
        perDisplayConfigs[displayUUID] = config
        
        let newConfig = DisplayConfig(
            targetDisplayUUID: displayConfig.targetDisplayUUID,
            showOnAllDisplays: displayConfig.showOnAllDisplays,
            followMainDisplay: displayConfig.followMainDisplay,
            multiDisplayMode: displayConfig.multiDisplayMode,
            enabledDisplayUUIDs: displayConfig.enabledDisplayUUIDs,
            perDisplayConfigurations: perDisplayConfigs,
            syncConfigurationAcrossDisplays: displayConfig.syncConfigurationAcrossDisplays,
            autoDetectNewDisplays: displayConfig.autoDetectNewDisplays,
            rememberDisplayPreferences: displayConfig.rememberDisplayPreferences
        )
        preferencesManager.displayConfig = newConfig
        
        // 更新对应显示器的窗口配置
        if let displayWindow = activeDisplayWindows[displayUUID] {
            applyPerDisplayConfig(to: displayWindow, config: config)
        }
        
        print("🖥️ 已更新显示器 \(displayUUID) 的专属配置")
    }
    
    /// 获取所有可用显示器信息
    func getAvailableDisplays() -> [DisplayInfo] {
        return displayManager.displays
    }
    
    /// 获取指定显示器的当前配置
    func getDisplayConfig(_ displayUUID: String) -> PerDisplayConfig? {
        return preferencesManager.displayConfig.perDisplayConfigurations[displayUUID]
    }
    
    /// 同步配置到所有显示器
    func syncConfigurationToAllDisplays() {
        guard preferencesManager.displayConfig.syncConfigurationAcrossDisplays else { return }
        
        let baseAppearance = preferencesManager.appearanceConfig
        let baseTimeFormat = preferencesManager.timeFormat
        
        for displayUUID in activeDisplayWindows.keys {
            let config = PerDisplayConfig(
                displayUUID: displayUUID,
                isEnabled: true,
                windowPosition: .topRight,
                customPoint: nil,
                appearanceOverrides: baseAppearance,
                timeFormatOverrides: baseTimeFormat
            )
            setPerDisplayConfig(displayUUID, config: config)
        }
        
        print("🔄 已同步配置到所有显示器")
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // 监听显示器变化
        displayManager.$displays
            .sink { [weak self] _ in
                self?.handleDisplaysChanged()
            }
            .store(in: &cancellables)
        
        // 监听显示器配置变化
        preferencesManager.$displayConfig
            .sink { [weak self] _ in
                self?.updateDisplayConfiguration()
            }
            .store(in: &cancellables)
    }
    
    private func updateDisplayConfiguration() {
        let config = preferencesManager.displayConfig
        currentMode = config.multiDisplayMode
        isMultiDisplayEnabled = config.multiDisplayMode != .singleDisplay
        
        updateDisplayWindows()
        
        // 启动光标跟踪（如果需要）
        if config.multiDisplayMode == .followCursor {
            startCursorTracking()
        } else {
            stopCursorTracking()
        }
    }
    
    private func updateDisplayWindows() {
        let config = preferencesManager.displayConfig
        let displays = displayManager.displays
        
        switch config.multiDisplayMode {
        case .singleDisplay:
            // 保持单个窗口（由主 WindowManager 管理）
            cleanupAllWindows()
            
        case .mainDisplayOnly:
            // 只在主显示器显示
            cleanupAllWindows()
            if let mainDisplay = displayManager.mainDisplay {
                createWindowForDisplay(mainDisplay)
            }
            
        case .allDisplays:
            // 在所有显示器显示
            cleanupAllWindows()
            for display in displays {
                createWindowForDisplay(display)
            }
            
        case .selectedDisplays:
            // 在选定的显示器显示
            cleanupAllWindows()
            for display in displays {
                if config.enabledDisplayUUIDs.contains(display.uuid) {
                    createWindowForDisplay(display)
                }
            }
            
        case .followCursor:
            // 跟随光标模式（动态创建）
            handleCursorFollowMode()
        }
    }
    
    private func createWindowForDisplay(_ display: DisplayInfo) {
        // 避免重复创建
        guard activeDisplayWindows[display.uuid] == nil else { return }
        
        // 创建独立的视图模型
        let viewModel = ClockViewModel()
        
        // 应用显示器专属配置（如果有）
        if let perDisplayConfig = preferencesManager.displayConfig.perDisplayConfigurations[display.uuid] {
            applyPerDisplayConfig(to: viewModel, config: perDisplayConfig)
        }
        
        // 创建窗口控制器
        let controller = ClockWindowController(viewModel: viewModel)
        
        // 设置窗口位置到指定显示器
        if let window = controller.clockWindow {
            positionWindowOnDisplay(window, display: display)
        }
        
        // 显示窗口
        controller.showWindow()
        
        // 保存窗口信息
        guard let window = controller.clockWindow else { return }
        let displayWindow = DisplayWindow(
            displayUUID: display.uuid,
            window: window,
            controller: controller,
            viewModel: viewModel
        )
        activeDisplayWindows[display.uuid] = displayWindow
        
        print("🖥️ 已在显示器 \(display.name) 创建时钟窗口")
    }
    
    private func positionWindowOnDisplay(_ window: NSWindow?, display: DisplayInfo) {
        guard let window = window else { return }
        
        let config = getDisplayConfig(display.uuid)
        let position = config?.windowPosition ?? .topRight
        let customPoint = config?.customPoint
        
        // 计算在指定显示器上的位置
        var windowFrame = window.frame
        let displayFrame = display.frame
        
        if let customPoint = customPoint {
            // 使用自定义位置
            windowFrame.origin = CGPoint(
                x: displayFrame.origin.x + customPoint.x,
                y: displayFrame.origin.y + customPoint.y
            )
        } else {
            // 使用预设位置
            let margin = CGFloat(20)
            
            switch position {
            case .topLeft:
                windowFrame.origin = CGPoint(
                    x: displayFrame.minX + margin,
                    y: displayFrame.maxY - windowFrame.height - margin
                )
            case .topRight:
                windowFrame.origin = CGPoint(
                    x: displayFrame.maxX - windowFrame.width - margin,
                    y: displayFrame.maxY - windowFrame.height - margin
                )
            case .bottomLeft:
                windowFrame.origin = CGPoint(
                    x: displayFrame.minX + margin,
                    y: displayFrame.minY + margin
                )
            case .bottomRight:
                windowFrame.origin = CGPoint(
                    x: displayFrame.maxX - windowFrame.width - margin,
                    y: displayFrame.minY + margin
                )
            case .topCenter:
                windowFrame.origin = CGPoint(
                    x: displayFrame.minX + (displayFrame.width - windowFrame.width) / 2,
                    y: displayFrame.maxY - windowFrame.height - margin
                )
            case .bottomCenter:
                windowFrame.origin = CGPoint(
                    x: displayFrame.minX + (displayFrame.width - windowFrame.width) / 2,
                    y: displayFrame.minY + margin
                )
            case .custom:
                // 自定义位置已在上面处理
                break
            }
        }
        
        window.setFrame(windowFrame, display: true)
    }
    
    private func applyPerDisplayConfig(to viewModel: ClockViewModel, config: PerDisplayConfig) {
        // 应用外观覆盖
        if let appearanceOverrides = config.appearanceOverrides {
            viewModel.preferencesManager.appearanceConfig = appearanceOverrides
        }
        
        // 应用时间格式覆盖
        if let timeFormatOverrides = config.timeFormatOverrides {
            viewModel.preferencesManager.timeFormat = timeFormatOverrides
        }
    }
    
    private func applyPerDisplayConfig(to displayWindow: DisplayWindow, config: PerDisplayConfig) {
        applyPerDisplayConfig(to: displayWindow.viewModel, config: config)
        
        // 更新窗口位置
        if let display = displayManager.getDisplay(by: displayWindow.displayUUID) {
            positionWindowOnDisplay(displayWindow.window, display: display)
        }
    }
    
    private func cleanupAllWindows() {
        for (_, displayWindow) in activeDisplayWindows {
            displayWindow.window.close()
        }
        activeDisplayWindows.removeAll()
    }
    
    private func handleDisplaysChanged() {
        guard isMultiDisplayEnabled else { return }
        
        let config = preferencesManager.displayConfig
        
        // 如果启用了自动检测新显示器
        if config.autoDetectNewDisplays {
            updateDisplayWindows()
        }
        
        // 移除已断开显示器的窗口
        let currentDisplayUUIDs = Set(displayManager.displays.map { $0.uuid })
        let activeDisplayUUIDs = Set(activeDisplayWindows.keys)
        
        for disconnectedUUID in activeDisplayUUIDs.subtracting(currentDisplayUUIDs) {
            if let displayWindow = activeDisplayWindows[disconnectedUUID] {
                displayWindow.window.close()
                activeDisplayWindows.removeValue(forKey: disconnectedUUID)
                print("🖥️ 已移除断开显示器 \(disconnectedUUID) 的时钟窗口")
            }
        }
    }
    
    private func startCursorTracking() {
        stopCursorTracking()
        
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkCursorDisplay()
            }
        }
        
        print("🖱️ 已启动光标跟踪")
    }
    
    private func stopCursorTracking() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
    }
    
    private func checkCursorDisplay() {
        let mouseLocation = NSEvent.mouseLocation
        
        // 找到鼠标所在的显示器
        guard let currentDisplay = displayManager.displays.first(where: { display in
            display.frame.contains(mouseLocation)
        }) else { return }
        
        // 如果显示器没有变化，则不需要操作
        guard currentDisplay.uuid != lastCursorDisplayUUID else { return }
        
        lastCursorDisplayUUID = currentDisplay.uuid
        handleCursorFollowMode()
    }
    
    private func handleCursorFollowMode() {
        guard currentMode == .followCursor else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        // 找到鼠标所在的显示器
        guard let currentDisplay = displayManager.displays.first(where: { display in
            display.frame.contains(mouseLocation)
        }) else { return }
        
        // 清理其他显示器的窗口
        for (uuid, displayWindow) in activeDisplayWindows {
            if uuid != currentDisplay.uuid {
                displayWindow.window.close()
                activeDisplayWindows.removeValue(forKey: uuid)
            }
        }
        
        // 在当前显示器创建窗口（如果还没有）
        if activeDisplayWindows[currentDisplay.uuid] == nil {
            createWindowForDisplay(currentDisplay)
        }
    }
}

// MARK: - Extensions

extension MultiDisplayManager {
    /// 获取多显示器统计信息
    func getDisplayStatistics() -> MultiDisplayStatistics {
        return MultiDisplayStatistics(
            totalDisplays: displayManager.displays.count,
            activeWindows: activeDisplayWindows.count,
            currentMode: currentMode,
            isEnabled: isMultiDisplayEnabled
        )
    }
}

/// 多显示器统计信息
struct MultiDisplayStatistics {
    let totalDisplays: Int
    let activeWindows: Int
    let currentMode: MultiDisplayMode
    let isEnabled: Bool
    
    var description: String {
        return """
        显示器总数: \(totalDisplays)
        活动窗口: \(activeWindows)
        当前模式: \(currentMode.displayName)
        多显示器: \(isEnabled ? "启用" : "禁用")
        """
    }
}