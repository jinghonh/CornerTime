//
//  AppLifecycle.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import ServiceManagement
import Foundation

/// 应用生命周期管理器
@MainActor
class AppLifecycle: ObservableObject {
    // MARK: - Published Properties
    @Published var isLaunchAtLoginEnabled: Bool = false
    
    // MARK: - Private Properties
    private let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.cornertime.app"
    
    // MARK: - Initialization
    init() {
        checkLaunchAtLoginStatus()
        setupApplicationBehavior()
    }
    
    // MARK: - Public Methods
    
    /// 设置开机启动
    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            setLaunchAtLoginModern(enabled)
        } else {
            setLaunchAtLoginLegacy(enabled)
        }
        isLaunchAtLoginEnabled = enabled
    }
    
    /// 隐藏应用图标（从 Dock 中移除）
    func hideFromDock() {
        NSApp.setActivationPolicy(.accessory)
    }
    
    /// 显示应用图标（在 Dock 中显示）
    func showInDock() {
        NSApp.setActivationPolicy(.regular)
    }
    
    /// 优雅退出应用
    func quitApplication() {
        NSApp.terminate(nil)
    }
    
    /// 重启应用
    func restartApplication() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        
        NSApp.terminate(nil)
    }
    
    /// 检查应用是否有必要的权限
    func checkPermissions() -> Bool {
        // 检查辅助功能权限（如果需要）
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let options = [checkOptPrompt: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        return accessEnabled
    }
    
    /// 请求必要权限
    func requestPermissions() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let options = [checkOptPrompt: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Private Methods
    
    private func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            checkLaunchAtLoginStatusModern()
        } else {
            checkLaunchAtLoginStatusLegacy()
        }
    }
    
    @available(macOS 13.0, *)
    private func checkLaunchAtLoginStatusModern() {
        let service = SMAppService.mainApp
        isLaunchAtLoginEnabled = service.status == .enabled
    }
    
    private func checkLaunchAtLoginStatusLegacy() {
        // 使用较老的 API 检查登录项状态
        // 这里简化处理，实际项目中可能需要更复杂的逻辑
        isLaunchAtLoginEnabled = false
    }
    
    @available(macOS 13.0, *)
    private func setLaunchAtLoginModern(_ enabled: Bool) {
        do {
            let service = SMAppService.mainApp
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("设置开机启动失败: \(error)")
        }
    }
    
    private func setLaunchAtLoginLegacy(_ enabled: Bool) {
        // 使用较老的 SMLoginItemSetEnabled API
        let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        if !success {
            print("设置开机启动失败（Legacy API）")
        }
    }
    
    private func setupApplicationBehavior() {
        // 设置应用行为，默认隐藏Dock图标
        hideFromDock()
        
        // 监听应用将要退出的通知
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleApplicationWillTerminate()
        }
        
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleApplicationDidResignActive()
        }
        
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleApplicationDidBecomeActive()
        }
    }
    
    private func handleApplicationWillTerminate() {
        // 应用退出前的清理工作
        print("应用即将退出，执行清理工作")
    }
    
    private func handleApplicationDidResignActive() {
        // 应用进入后台时的处理
        print("应用进入后台")
    }
    
    private func handleApplicationDidBecomeActive() {
        // 应用进入前台时的处理
        print("应用进入前台")
    }
}