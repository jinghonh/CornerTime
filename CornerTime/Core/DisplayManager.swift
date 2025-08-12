//
//  DisplayManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import Foundation
import Combine

/// 显示器信息
struct DisplayInfo {
    let uuid: String
    let name: String
    let frame: CGRect
    let isMain: Bool
    let screen: NSScreen
    
    init(screen: NSScreen) {
        self.screen = screen
        self.frame = screen.frame
        self.isMain = screen == NSScreen.main
        
        // 获取显示器UUID - 使用字符串表示避免整数溢出
        if let uuid = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            self.uuid = "display_\(uuid.stringValue)"
        } else {
            self.uuid = "display_unknown"
        }
        
        // 获取显示器名称
        self.name = screen.localizedName
    }
}

/// 显示器管理器，负责多显示器检测和拓扑变化监听
@MainActor
class DisplayManager: ObservableObject {
    // MARK: - Published Properties
    @Published var displays: [DisplayInfo] = []
    @Published var mainDisplay: DisplayInfo?
    @Published var currentDisplay: DisplayInfo?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var isInitialized = false
    private var updateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        setupDisplayMonitoring()
        updateDisplays()
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 获取指定UUID的显示器
    func getDisplay(by uuid: String) -> DisplayInfo? {
        return displays.first { $0.uuid == uuid }
    }
    
    /// 获取最佳显示器（用于窗口显示）
    func getBestDisplay(for config: DisplayConfig) -> DisplayInfo? {
        if config.showOnAllDisplays {
            return mainDisplay
        }
        
        if let targetUUID = config.targetDisplayUUID,
           let targetDisplay = getDisplay(by: targetUUID) {
            return targetDisplay
        }
        
        if config.followMainDisplay {
            return mainDisplay
        }
        
        return displays.first ?? mainDisplay
    }
    
    /// 更新当前使用的显示器
    func setCurrentDisplay(_ display: DisplayInfo?) {
        currentDisplay = display
    }
    
    // MARK: - Private Methods
    
    private func setupDisplayMonitoring() {
        // 监听显示器配置变化（带防抖机制）
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleDisplayUpdate()
        }
    }
    
    private func scheduleDisplayUpdate() {
        // 取消之前的更新任务
        updateTask?.cancel()
        
        // 延迟100ms执行更新，避免频繁触发
        updateTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            if !Task.isCancelled {
                updateDisplays()
            }
        }
    }
    
    func updateDisplays() {
        let newDisplays = NSScreen.screens.map { DisplayInfo(screen: $0) }
        
        // 检查是否有变化（仅在初始化后进行比较）
        if isInitialized {
            let displayUUIDs = Set(displays.map { $0.uuid })
            let newDisplayUUIDs = Set(newDisplays.map { $0.uuid })
            
            if displayUUIDs != newDisplayUUIDs {
                print("显示器配置发生变化")
                print("原显示器: \(Array(displayUUIDs).sorted())")
                print("新显示器: \(Array(newDisplayUUIDs).sorted())")
            }
        }
        
        displays = newDisplays
        mainDisplay = displays.first { $0.isMain }
        
        // 标记为已初始化
        if !isInitialized {
            isInitialized = true
            print("🖥️ 显示器管理器初始化完成，检测到 \(displays.count) 个显示器")
        }
        
        // 如果当前显示器不再可用，切换到主显示器
        if let current = currentDisplay,
           !displays.contains(where: { $0.uuid == current.uuid }) {
            currentDisplay = mainDisplay
        }
    }
}

// MARK: - Extensions

extension NSScreen {
    var uuid: String {
        if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "display_\(screenNumber.stringValue)"
        }
        return "display_unknown"
    }
}