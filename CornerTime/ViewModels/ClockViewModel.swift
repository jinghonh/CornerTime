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
        
        setupBindings()
        setupHotKeys()
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
    
    /// 切换点击穿透
    func toggleClickThrough() {
        allowsClickThrough.toggle()
        updateWindowConfig()
    }
    
    /// 更新时间格式
    func updateTimeFormat(_ format: TimeFormat) {
        preferencesManager.timeFormat = format
    }
    
    /// 更新窗口位置
    func updateWindowPosition(_ position: WindowPosition) {
        var config = preferencesManager.windowConfig
        config = WindowConfig(
            position: position,
            customPoint: config.customPoint,
            margin: config.margin,
            isLocked: config.isLocked,
            allowsClickThrough: config.allowsClickThrough
        )
        preferencesManager.windowConfig = config
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
    
    private func updateWindowConfig() {
        let currentConfig = preferencesManager.windowConfig
        let newConfig = WindowConfig(
            position: currentConfig.position,
            customPoint: currentConfig.customPoint,
            margin: currentConfig.margin,
            isLocked: isLocked,
            allowsClickThrough: allowsClickThrough
        )
        preferencesManager.windowConfig = newConfig
    }
}