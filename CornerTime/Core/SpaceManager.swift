//
//  SpaceManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import Foundation
import Combine

/// 空间变化事件类型
enum SpaceChangeEvent {
    case spaceChanged(from: Int?, to: Int?)
    case activeDisplayChanged
    case fullScreenStateChanged(isFullScreen: Bool)
    case missionControlOpened
    case missionControlClosed
}

/// 空间管理器，负责监听和处理系统空间变化
@MainActor
class SpaceManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSpaceID: Int?
    @Published var isInFullScreen: Bool = false
    @Published var isMissionControlActive: Bool = false
    @Published var spaceChangeEvents = PassthroughSubject<SpaceChangeEvent, Never>()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var workspaceObserver: NSObjectProtocol?
    private var screenParametersObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init() {
        setupObservers()
        updateCurrentState()
    }
    
    deinit {
        Task { @MainActor in
            removeObservers()
        }
    }
    
    // MARK: - Public Methods
    
    /// 检查当前是否在全屏模式
    func checkFullScreenState() -> Bool {
        // 检查是否有全屏窗口
        for screen in NSScreen.screens {
            let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
            
            for windowInfo in windows {
                if let windowLevel = windowInfo[kCGWindowLayer as String] as? Int,
                   let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                   let windowWidth = bounds["Width"] as? CGFloat,
                   let windowHeight = bounds["Height"] as? CGFloat {
                    
                    // 检查窗口是否覆盖整个屏幕（全屏）
                    let screenFrame = screen.frame
                    if abs(windowWidth - screenFrame.width) < 1 && abs(windowHeight - screenFrame.height) < 1 && windowLevel == 0 {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /// 获取当前激活的应用程序信息
    func getCurrentActiveApp() -> (name: String?, isFullScreen: Bool) {
        let activeApp = NSWorkspace.shared.frontmostApplication
        let appName = activeApp?.localizedName
        
        // 检查活动应用是否处于全屏模式
        let isFullScreen = checkFullScreenState()
        
        return (appName, isFullScreen)
    }
    
    /// 强制更新窗口层级（用于确保在特殊情况下仍然可见）
    func forceWindowToFront(_ window: NSWindow, with level: NSWindow.Level) {
        window.level = level
        window.orderFrontRegardless()
        
        // 短暂延迟后再次确保窗口在前面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.orderFrontRegardless()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // 监听工作空间变化
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSpaceChange()
            }
        }
        
        // 监听应用激活变化
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleApplicationActivated(notification)
            }
        }
        
        // 监听屏幕参数变化
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenParametersChange()
            }
        }
        
        // 监听窗口级别变化（用于检测全屏模式）
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateFullScreenState()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateFullScreenState()
            }
        }
    }
    
    private func removeObservers() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        if let observer = screenParametersObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateCurrentState() {
        updateFullScreenState()
        // 这里可以添加更多状态更新逻辑
    }
    
    private func handleSpaceChange() {
        let oldSpaceID = currentSpaceID
        // 由于 macOS 没有公开 API 获取空间 ID，我们使用其他方式检测变化
        
        let newSpaceID = generateSpaceIdentifier()
        
        if oldSpaceID != newSpaceID {
            currentSpaceID = newSpaceID
            spaceChangeEvents.send(.spaceChanged(from: oldSpaceID, to: newSpaceID))
            print("空间发生变化: \(oldSpaceID ?? -1) -> \(newSpaceID ?? -1)")
        }
    }
    
    private func handleApplicationActivated(_ notification: Notification) {
        updateFullScreenState()
        
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            print("应用激活: \(app.localizedName ?? "Unknown")")
        }
    }
    
    private func handleScreenParametersChange() {
        spaceChangeEvents.send(.activeDisplayChanged)
        updateFullScreenState()
        print("屏幕参数发生变化")
    }
    
    private func updateFullScreenState() {
        let wasFullScreen = isInFullScreen
        isInFullScreen = checkFullScreenState()
        
        if wasFullScreen != isInFullScreen {
            spaceChangeEvents.send(.fullScreenStateChanged(isFullScreen: isInFullScreen))
            print("全屏状态变化: \(isInFullScreen)")
        }
    }
    
    private func generateSpaceIdentifier() -> Int? {
        // 由于没有公开的空间 ID API，我们使用组合信息生成标识符
        let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
        let screenConfig = NSScreen.screens.map { "\($0.frame)" }.joined()
        
        let identifier = "\(activeApp)_\(screenConfig)".hash
        return abs(identifier)
    }
}

// MARK: - Extensions

extension SpaceManager {
    /// 获取推荐的窗口层级
    func getRecommendedWindowLevel(for config: BehaviorConfig) -> NSWindow.Level {
        if isInFullScreen && config.showInFullScreen {
            // 在全屏模式下，使用更高的层级确保可见
            switch config.windowLevel {
            case .normal, .floating:
                return .statusBar
            case .statusBar:
                return .modalPanel
            case .modalPanel, .popupMenu:
                return config.windowLevel.nsWindowLevel
            }
        }
        
        return config.windowLevel.nsWindowLevel
    }
    
    /// 获取推荐的集合行为
    func getRecommendedCollectionBehavior(for config: BehaviorConfig) -> NSWindow.CollectionBehavior {
        var behavior: NSWindow.CollectionBehavior = []
        
        if config.showInAllSpaces {
            behavior.insert(.canJoinAllSpaces)
        }
        
        if config.showInFullScreen {
            behavior.insert(.fullScreenAuxiliary)
        }
        
        if config.stayOnTop {
            behavior.insert(.stationary)
        }
        
        // 默认不参与窗口循环
        behavior.insert(.ignoresCycle)
        
        return behavior
    }
}