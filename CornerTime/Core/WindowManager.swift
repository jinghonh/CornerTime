//
//  WindowManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import Foundation
import Combine

/// 窗口位置枚举
enum WindowPosition: String, CaseIterable, Codable {
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    case topCenter = "topCenter"
    case bottomCenter = "bottomCenter"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .topLeft: return "左上角"
        case .topRight: return "右上角"
        case .bottomLeft: return "左下角"
        case .bottomRight: return "右下角"
        case .topCenter: return "顶部居中"
        case .bottomCenter: return "底部居中"
        case .custom: return "自定义位置"
        }
    }
}

/// 窗口配置
struct WindowConfig: Codable {
    let position: WindowPosition
    let customPoint: CGPoint?
    let margin: CGFloat
    let isLocked: Bool
    let allowsClickThrough: Bool
    
    init(position: WindowPosition = .topRight,
         customPoint: CGPoint? = nil,
         margin: CGFloat = 20,
         isLocked: Bool = false,
         allowsClickThrough: Bool = false) {
        self.position = position
        self.customPoint = customPoint
        self.margin = margin
        self.isLocked = isLocked
        self.allowsClickThrough = allowsClickThrough
    }
}

/// 窗口管理器，负责窗口层级、位置管理、空间行为
@MainActor
class WindowManager: ObservableObject {
    // MARK: - Published Properties
    @Published var windowConfig: WindowConfig = WindowConfig()
    @Published var isVisible: Bool = true
    
    // MARK: - Private Properties
    private var clockWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupWindowObservers()
    }
    
    // MARK: - Public Methods
    
    /// 创建时钟窗口
    func createClockWindow(contentView: NSView, behaviorConfig: BehaviorConfig, spaceManager: SpaceManager) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 窗口基础设置
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = windowConfig.allowsClickThrough
        
        // 动态设置窗口层级和行为
        updateWindowLevelAndBehavior(window: window, behaviorConfig: behaviorConfig, spaceManager: spaceManager)
        
        // 设置内容视图
        window.contentView = contentView
        
        clockWindow = window
        updateWindowPosition()
        
        if isVisible {
            showWindow()
        }
    }
    
    /// 更新窗口层级和行为
    func updateWindowLevelAndBehavior(window: NSWindow, behaviorConfig: BehaviorConfig, spaceManager: SpaceManager) {
        // 根据当前状态和配置动态设置窗口层级
        let recommendedLevel = spaceManager.getRecommendedWindowLevel(for: behaviorConfig)
        window.level = recommendedLevel
        
        // 设置集合行为
        let recommendedBehavior = spaceManager.getRecommendedCollectionBehavior(for: behaviorConfig)
        window.collectionBehavior = recommendedBehavior
        
        print("窗口层级设置为: \(recommendedLevel), 行为: \(recommendedBehavior)")
    }
    
    /// 强制刷新窗口状态（用于应对特殊情况）
    func refreshWindowState(behaviorConfig: BehaviorConfig, spaceManager: SpaceManager) {
        guard let window = clockWindow else { return }
        
        updateWindowLevelAndBehavior(window: window, behaviorConfig: behaviorConfig, spaceManager: spaceManager)
        
        // 确保窗口仍然可见
        if isVisible {
            spaceManager.forceWindowToFront(window, with: window.level)
        }
    }
    
    /// 显示窗口
    func showWindow() {
        guard let window = clockWindow else { return }
        window.orderFrontRegardless()
        isVisible = true
    }
    
    /// 隐藏窗口
    func hideWindow() {
        clockWindow?.orderOut(nil)
        isVisible = false
    }
    
    /// 切换窗口可见性
    func toggleVisibility() {
        if isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    /// 更新窗口配置
    func updateConfig(_ config: WindowConfig) {
        windowConfig = config
        updateWindowProperties()
        updateWindowPosition()
    }
    
    /// 更新窗口位置
    func updateWindowPosition() {
        guard let window = clockWindow,
              let screen = getTargetScreen() else { return }
        
        let windowSize = window.frame.size
        let screenFrame = screen.visibleFrame
        let safeAreaInsets = getSafeAreaInsets(for: screen)
        
        let position: CGPoint
        
        switch windowConfig.position {
        case .topLeft:
            position = CGPoint(
                x: screenFrame.minX + windowConfig.margin + safeAreaInsets.left,
                y: screenFrame.maxY - windowSize.height - windowConfig.margin - safeAreaInsets.top
            )
        case .topRight:
            position = CGPoint(
                x: screenFrame.maxX - windowSize.width - windowConfig.margin - safeAreaInsets.right,
                y: screenFrame.maxY - windowSize.height - windowConfig.margin - safeAreaInsets.top
            )
        case .bottomLeft:
            position = CGPoint(
                x: screenFrame.minX + windowConfig.margin + safeAreaInsets.left,
                y: screenFrame.minY + windowConfig.margin + safeAreaInsets.bottom
            )
        case .bottomRight:
            position = CGPoint(
                x: screenFrame.maxX - windowSize.width - windowConfig.margin - safeAreaInsets.right,
                y: screenFrame.minY + windowConfig.margin + safeAreaInsets.bottom
            )
        case .topCenter:
            position = CGPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.maxY - windowSize.height - windowConfig.margin - safeAreaInsets.top
            )
        case .bottomCenter:
            position = CGPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.minY + windowConfig.margin + safeAreaInsets.bottom
            )
        case .custom:
            position = windowConfig.customPoint ?? CGPoint(x: screenFrame.midX, y: screenFrame.midY)
        }
        
        // 确保位置在屏幕可见范围内
        let safePosition = ensurePositionInBounds(position, windowSize: windowSize, screenFrame: screenFrame)
        
        // 临时禁用窗口委托，防止programmatic移动触发windowDidMove
        let originalDelegate = window.delegate
        window.delegate = nil
        
        window.setFrameOrigin(safePosition)
        
        // 恢复窗口委托
        window.delegate = originalDelegate
    }
    
    /// 确保窗口位置在屏幕边界内
    private func ensurePositionInBounds(_ position: CGPoint, windowSize: NSSize, screenFrame: NSRect) -> CGPoint {
        var safePosition = position
        
        // 确保窗口不会超出屏幕右边界
        if safePosition.x + windowSize.width > screenFrame.maxX {
            safePosition.x = screenFrame.maxX - windowSize.width
        }
        
        // 确保窗口不会超出屏幕左边界
        if safePosition.x < screenFrame.minX {
            safePosition.x = screenFrame.minX
        }
        
        // 确保窗口不会超出屏幕上边界
        if safePosition.y + windowSize.height > screenFrame.maxY {
            safePosition.y = screenFrame.maxY - windowSize.height
        }
        
        // 确保窗口不会超出屏幕下边界
        if safePosition.y < screenFrame.minY {
            safePosition.y = screenFrame.minY
        }
        
        // 如果位置被修正了，输出调试信息
        if safePosition != position {
            print("⚠️ 窗口位置已修正: \(position) → \(safePosition)")
        }
        
        return safePosition
    }
    
    // MARK: - Private Methods
    
    private func setupWindowObservers() {
        // 监听窗口配置变化
        $windowConfig
            .sink { [weak self] _ in
                self?.updateWindowProperties()
                self?.updateWindowPosition()
            }
            .store(in: &cancellables)
        
        // 监听屏幕变化
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateWindowPosition()
            }
        }
    }
    
    private func updateWindowProperties() {
        guard let window = clockWindow else { return }
        
        // 更新点击穿透设置
        window.ignoresMouseEvents = windowConfig.allowsClickThrough
        
        // 更新窗口是否可移动
        window.isMovable = !windowConfig.isLocked
    }
    
    private func getTargetScreen() -> NSScreen? {
        // 目前返回主屏幕，后续可扩展为多显示器支持
        return NSScreen.main
    }
    
    private func getSafeAreaInsets(for screen: NSScreen) -> NSEdgeInsets {
        // 获取安全区域边距（处理刘海屏等）
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets
        } else {
            return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}