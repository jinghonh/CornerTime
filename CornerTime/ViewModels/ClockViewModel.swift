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
        // TODO: 实现设置窗口
        print("显示设置窗口")
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
        let currentConfig = preferencesManager.windowConfig
        let newConfig = WindowConfig(
            position: currentConfig.position,
            customPoint: currentConfig.customPoint,
            margin: currentConfig.margin,
            isLocked: currentConfig.isLocked,
            allowsClickThrough: currentConfig.allowsClickThrough,
            enableDragging: enableDragging,
            enableSnapping: enableSnapping,
            snapDistance: snapDistance,
            rememberPosition: currentConfig.rememberPosition,
            respectSafeArea: currentConfig.respectSafeArea,
            lastSavedPosition: currentConfig.lastSavedPosition
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
    
    /// 更新位置记忆设置
    func updatePositionMemory(enabled: Bool) {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = WindowConfig(
            position: currentConfig.position,
            customPoint: currentConfig.customPoint,
            margin: currentConfig.margin,
            isLocked: currentConfig.isLocked,
            allowsClickThrough: currentConfig.allowsClickThrough,
            enableDragging: currentConfig.enableDragging,
            enableSnapping: currentConfig.enableSnapping,
            snapDistance: currentConfig.snapDistance,
            rememberPosition: enabled,
            respectSafeArea: currentConfig.respectSafeArea,
            lastSavedPosition: enabled ? currentConfig.lastSavedPosition : nil
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
    
    /// 更新安全区域设置
    func updateSafeAreaSettings(respectSafeArea: Bool) {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = WindowConfig(
            position: currentConfig.position,
            customPoint: currentConfig.customPoint,
            margin: currentConfig.margin,
            isLocked: currentConfig.isLocked,
            allowsClickThrough: currentConfig.allowsClickThrough,
            enableDragging: currentConfig.enableDragging,
            enableSnapping: currentConfig.enableSnapping,
            snapDistance: currentConfig.snapDistance,
            rememberPosition: currentConfig.rememberPosition,
            respectSafeArea: respectSafeArea,
            lastSavedPosition: currentConfig.lastSavedPosition
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
        let newConfig = WindowConfig(
            position: .topRight, // 重置为默认位置
            customPoint: nil,
            margin: currentConfig.margin,
            isLocked: currentConfig.isLocked,
            allowsClickThrough: currentConfig.allowsClickThrough,
            enableDragging: currentConfig.enableDragging,
            enableSnapping: currentConfig.enableSnapping,
            snapDistance: currentConfig.snapDistance,
            rememberPosition: currentConfig.rememberPosition,
            respectSafeArea: currentConfig.respectSafeArea,
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
    
    private func updateWindowConfig() {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = WindowConfig(
            position: currentConfig.position,
            customPoint: currentConfig.customPoint,
            margin: currentConfig.margin,
            isLocked: isLocked,
            allowsClickThrough: allowsClickThrough,
            enableDragging: currentConfig.enableDragging,
            enableSnapping: currentConfig.enableSnapping,
            snapDistance: currentConfig.snapDistance,
            rememberPosition: currentConfig.rememberPosition,
            respectSafeArea: currentConfig.respectSafeArea,
            lastSavedPosition: currentConfig.lastSavedPosition
        )
        
        preferencesManager.updateWindowConfig(newConfig)
        windowManager.updateWindowConfigWithDragSupport(newConfig)
    }
}