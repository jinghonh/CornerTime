//
//  ClockViewModel.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation
import Combine
import SwiftUI
import AppKit

/// 时钟主视图模型，协调各个管理器
@MainActor
class ClockViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isVisible: Bool = true
    @Published var currentTime: String = ""
    @Published var isLocked: Bool = false
    @Published var allowsClickThrough: Bool = false
    
    // MARK: - Managers
    let clockCore: ClockCore
    let windowManager: WindowManager
    let preferencesManager: PreferencesManager
    let displayManager: DisplayManager
    let hotKeyManager: HotKeyManager
    let appLifecycle: AppLifecycle
    let spaceManager: SpaceManager
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?
    
    // MARK: - Initialization
    init() {
        // 初始化所有管理器
        self.clockCore = ClockCore()
        self.windowManager = WindowManager()
        self.preferencesManager = PreferencesManager()
        self.displayManager = DisplayManager()
        self.hotKeyManager = HotKeyManager()
        self.appLifecycle = AppLifecycle()
        self.spaceManager = SpaceManager()
        
        setupBindings()
        setupHotKeys()
        setupSpaceManager()
        setupInitialConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// 切换可见性
    func toggleVisibility() {
        isVisible.toggle()
        windowManager.isVisible = isVisible
        
        if isVisible {
            windowManager.showWindow()
        } else {
            windowManager.hideWindow()
        }
    }
    
    /// 切换位置锁定
    func toggleLock() {
        isLocked.toggle()
        updateWindowConfig()
    }
    

    
    /// 更新时间格式
    func updateTimeFormat(_ format: TimeFormat) {
        preferencesManager.timeFormat = format
    }
    
    /// 更新窗口位置
    func updateWindowPosition(_ position: WindowPosition) {
        let config = preferencesManager.windowConfig
        let newConfig = WindowConfig(
            position: position,
            customPoint: config.customPoint,
            margin: config.margin,
            isLocked: config.isLocked,
            allowsClickThrough: config.allowsClickThrough,
            enableDragging: config.enableDragging,
            enableSnapping: config.enableSnapping,
            snapDistance: config.snapDistance,
            rememberPosition: config.rememberPosition,
            respectSafeArea: config.respectSafeArea,
            lastSavedPosition: config.lastSavedPosition
        )
        preferencesManager.windowConfig = newConfig
    }
    
    /// 显示设置窗口
    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsWindow(viewModel: self)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "CornerTime 设置"
        window.contentView = NSHostingView(rootView: settingsView)
        window.isReleasedWhenClosed = false
        
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 退出应用
    func quitApplication() {
        appLifecycle.quitApplication()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 绑定时钟核心的时间更新
        clockCore.$formattedTime
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentTime, on: self)
            .store(in: &cancellables)
        
        // 绑定偏好设置到时钟核心
        preferencesManager.$timeFormat
            .sink { [weak self] format in
                self?.clockCore.updateTimeFormat(format)
            }
            .store(in: &cancellables)
        
        // 绑定偏好设置到窗口管理器
        preferencesManager.$windowConfig
            .sink { [weak self] config in
                self?.windowManager.updateConfig(config)
                self?.isLocked = config.isLocked
                self?.allowsClickThrough = config.allowsClickThrough
            }
            .store(in: &cancellables)
        
        // 绑定窗口管理器的可见性
        windowManager.$isVisible
            .assign(to: \.isVisible, on: self)
            .store(in: &cancellables)
        
        // 绑定行为配置到应用生命周期
        preferencesManager.$behaviorConfig
            .sink { [weak self] config in
                self?.appLifecycle.setLaunchAtLogin(config.launchAtLogin)
                
                if config.hideFromDock {
                    self?.appLifecycle.hideFromDock()
                } else {
                    self?.appLifecycle.showInDock()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupHotKeys() {
        hotKeyManager.registerDefaultHotKeys(
            onToggleVisibility: { [weak self] in
                self?.toggleVisibility()
            },
            onToggleLock: { [weak self] in
                self?.toggleLock()
            },
            onToggleClickThrough: { [weak self] in
                self?.toggleClickThrough()
            }
        )
    }
    
    private func setupInitialConfiguration() {
        // 初始化配置
        isLocked = preferencesManager.windowConfig.isLocked
        allowsClickThrough = preferencesManager.windowConfig.allowsClickThrough
        isVisible = true
        
        // 应用行为配置
        let behaviorConfig = preferencesManager.behaviorConfig
        appLifecycle.setLaunchAtLogin(behaviorConfig.launchAtLogin)
        
        if behaviorConfig.hideFromDock {
            appLifecycle.hideFromDock()
        }
    }
    
    private func setupSpaceManager() {
        // 监听空间变化事件
        spaceManager.spaceChangeEvents
            .sink { [weak self] event in
                self?.handleSpaceChangeEvent(event)
            }
            .store(in: &cancellables)
        
        // 监听全屏状态变化
        spaceManager.$isInFullScreen
            .sink { [weak self] isFullScreen in
                self?.handleFullScreenStateChange(isFullScreen)
            }
            .store(in: &cancellables)
    }
    
    private func handleSpaceChangeEvent(_ event: SpaceChangeEvent) {
        print("空间变化事件: \(event)")
        
        switch event {
        case .spaceChanged(let from, let to):
            print("空间切换: \(from ?? -1) -> \(to ?? -1)")
            // 确保窗口在新空间中仍然可见
            refreshWindowVisibility()
            
        case .activeDisplayChanged:
            print("活动显示器变化")
            // 重新计算窗口位置
            windowManager.updateWindowPosition()
            
        case .fullScreenStateChanged(let isFullScreen):
            print("全屏状态变化: \(isFullScreen)")
            refreshWindowConfiguration()
            
        case .missionControlOpened:
            print("Mission Control 打开")
            
        case .missionControlClosed:
            print("Mission Control 关闭")
            refreshWindowVisibility()
        }
    }
    
    private func handleFullScreenStateChange(_ isFullScreen: Bool) {
        print("全屏状态更新: \(isFullScreen)")
        
        // 根据全屏状态调整窗口行为
        refreshWindowConfiguration()
        
        // 如果进入全屏且配置为在全屏中显示，确保窗口可见
        if isFullScreen && preferencesManager.behaviorConfig.showInFullScreen {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshWindowVisibility()
            }
        }
    }
    
    private func refreshWindowConfiguration() {
        let behaviorConfig = preferencesManager.behaviorConfig
        windowManager.refreshWindowState(behaviorConfig: behaviorConfig, spaceManager: spaceManager)
    }
    
    private func refreshWindowVisibility() {
        if isVisible {
            windowManager.showWindow()
        }
    }
    
    // MARK: - Position and Drag Support
    
    /// 更新拖拽设置
    func updateDragSettings(enableDragging: Bool, enableSnapping: Bool, snapDistance: CGFloat) {
        guard ConfigurationValidator.isValidSnapDistance(snapDistance) else {
            print("⚠️ 吸附距离无效: \(snapDistance)")
            return
        }
        
        let currentConfig = preferencesManager.windowConfig
        let newConfig = ConfigurationHelper.updateWindowConfig(
            currentConfig,
            enableDragging: enableDragging,
            enableSnapping: enableSnapping,
            snapDistance: snapDistance
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
    
    /// 更新位置记忆设置
    func updatePositionMemory(enabled: Bool) {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = ConfigurationHelper.updateWindowConfig(
            currentConfig,
            rememberPosition: enabled,
            lastSavedPosition: enabled ? currentConfig.lastSavedPosition : nil
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
    
    /// 更新安全区域设置
    func updateSafeAreaSettings(respectSafeArea: Bool) {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = ConfigurationHelper.updateWindowConfig(
            currentConfig,
            respectSafeArea: respectSafeArea
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
    
    /// 保存当前位置
    func saveCurrentPosition() {
        windowManager.saveCurrentPosition()
    }
    
    /// 重置位置到默认
    func resetToDefaultPosition() {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = ConfigurationHelper.updateWindowConfig(
            currentConfig,
            position: .topRight, // 重置为默认位置
            customPoint: nil,
            lastSavedPosition: nil // 清除保存的位置
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
    
    // MARK: - Click Through and Lock Support
    
    /// 切换位置锁定状态
    func togglePositionLock() {
        windowManager.togglePositionLock()
        
        // 更新本地状态
        let newConfig = windowManager.windowConfig
        preferencesManager.updateWindowConfig(newConfig)
        
        // 更新UI状态
        isLocked = newConfig.isLocked
    }
    
    /// 切换点击穿透状态
    func toggleClickThrough() {
        windowManager.toggleClickThrough()
        
        // 更新本地状态
        let newConfig = windowManager.windowConfig
        preferencesManager.updateWindowConfig(newConfig)
        
        // 更新UI状态
        allowsClickThrough = newConfig.allowsClickThrough
    }
    
    /// 设置位置锁定状态
    func setPositionLocked(_ locked: Bool) {
        if isLocked != locked {
            togglePositionLock()
        }
    }
    
    /// 设置点击穿透状态
    func setClickThrough(_ enabled: Bool) {
        if allowsClickThrough != enabled {
            toggleClickThrough()
        }
    }
    
    /// 获取当前锁定状态描述
    func getLockStatusDescription() -> String {
        if isLocked && allowsClickThrough {
            return "🔒👆 位置锁定 + 点击穿透"
        } else if isLocked {
            return "🔒 位置锁定"
        } else if allowsClickThrough {
            return "👆 点击穿透"
        } else {
            return "🔓 可交互"
        }
    }
    
    // MARK: - Appearance Controls
    
    /// 更新字体大小
    func updateFontSize(_ size: CGFloat) {
        guard ConfigurationValidator.isValidFontSize(size) else {
            print("⚠️ 字体大小无效: \(size)")
            return
        }
        
        let currentConfig = preferencesManager.appearanceConfig
        let newConfig = ConfigurationHelper.updateAppearanceConfig(currentConfig, fontSize: size)
        
        preferencesManager.appearanceConfig = newConfig
        print("📝 字体大小更新为: \(size)")
    }
    
    /// 更新字体粗细
    func updateFontWeight(_ weight: FontWeightOption) {
        let currentConfig = preferencesManager.appearanceConfig
        let newConfig = ConfigurationHelper.updateAppearanceConfig(currentConfig, fontWeight: weight)
        
        preferencesManager.appearanceConfig = newConfig
        print("📝 字体粗细更新为: \(weight.displayName)")
    }
    
    /// 更新字体设计
    func updateFontDesign(_ design: FontDesignOption) {
        let currentConfig = preferencesManager.appearanceConfig
        let newConfig = ConfigurationHelper.updateAppearanceConfig(currentConfig, fontDesign: design)
        
        preferencesManager.appearanceConfig = newConfig
        print("📝 字体设计更新为: \(design.displayName)")
    }
    
    /// 切换24小时制
    func toggle24HourFormat() {
        let currentFormat = preferencesManager.timeFormat
        let newFormat = ConfigurationHelper.updateTimeFormat(
            currentFormat,
            is24Hour: !currentFormat.is24Hour
        )
        
        preferencesManager.timeFormat = newFormat
        print("⏰ 时间格式切换为: \(newFormat.is24Hour ? "24小时制" : "12小时制")")
    }
    
    /// 切换秒显示
    func toggleSecondsDisplay() {
        let currentFormat = preferencesManager.timeFormat
        let newFormat = ConfigurationHelper.updateTimeFormat(
            currentFormat,
            showSeconds: !currentFormat.showSeconds
        )
        
        preferencesManager.timeFormat = newFormat
        print("⏱️ 秒显示切换为: \(newFormat.showSeconds ? "显示" : "隐藏")")
    }
    
    /// 更新日期格式
    func updateDateFormat(_ format: DateFormatOption) {
        let currentFormat = preferencesManager.timeFormat
        let newFormat = ConfigurationHelper.updateTimeFormat(
            currentFormat,
            showDate: format != .none,
            showWeekday: format == .weekday || format == .full,
            dateFormat: format
        )
        
        preferencesManager.timeFormat = newFormat
        print("📅 日期格式更新为: \(format.displayName)")
    }
    
    /// 更新透明度
    func updateOpacity(_ opacity: Double) {
        guard ConfigurationValidator.isValidOpacity(opacity) else {
            print("⚠️ 透明度无效: \(opacity)")
            return
        }
        
        let currentConfig = preferencesManager.appearanceConfig
        let newConfig = ConfigurationHelper.updateAppearanceConfig(currentConfig, opacity: opacity)
        
        preferencesManager.appearanceConfig = newConfig
        print("🌫️ 透明度更新为: \(Int(opacity * 100))%")
    }
    
    /// 切换阴影效果
    func toggleShadow() {
        let currentConfig = preferencesManager.appearanceConfig
        let newConfig = AppearanceConfig(
            fontSize: currentConfig.fontSize,
            fontWeight: currentConfig.fontWeight,
            fontDesign: currentConfig.fontDesign,
            opacity: currentConfig.opacity,
            backgroundColor: currentConfig.backgroundColor,
            cornerRadius: currentConfig.cornerRadius,
            useBlurBackground: currentConfig.useBlurBackground,
            enableShadow: !currentConfig.enableShadow,
            shadowRadius: currentConfig.shadowRadius,
            textColor: currentConfig.textColor,
            useSystemColors: currentConfig.useSystemColors
        )
        
        preferencesManager.appearanceConfig = newConfig
        print("💫 阴影效果切换为: \(newConfig.enableShadow ? "启用" : "禁用")")
    }
    
    /// 预设字体大小选项
    func getFontSizePresets() -> [CGFloat] {
        return AppConstants.UI.fontSizePresets
    }
    
    /// 获取当前外观描述
    func getAppearanceDescription() -> String {
        let config = preferencesManager.appearanceConfig
        let format = preferencesManager.timeFormat
        
        var parts: [String] = []
        parts.append("\(Int(config.fontSize))pt")
        parts.append(config.fontWeight.displayName)
        parts.append(format.is24Hour ? "24h" : "12h")
        
        if format.showSeconds {
            parts.append("显示秒")
        }
        
        if format.dateFormat != .none {
            parts.append("显示日期")
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func updateWindowConfig() {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = ConfigurationHelper.updateWindowConfig(
            currentConfig,
            isLocked: isLocked,
            allowsClickThrough: allowsClickThrough
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
}