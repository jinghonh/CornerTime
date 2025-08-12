//
//  ClockWindowController.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import SwiftUI
import Combine

/// 时钟窗口控制器，管理浮层时钟窗口
class ClockWindowController: NSObject {
    // MARK: - Properties
    private var clockWindow: NSWindow?
    private let viewModel: ClockViewModel
    private var hostingView: NSHostingView<ClockView>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(viewModel: ClockViewModel) {
        self.viewModel = viewModel
        super.init()
        Task { @MainActor in
            self.setupWindow()
            self.setupBindings()
        }
    }
    
    // MARK: - Public Methods
    
    /// 显示窗口
    @MainActor
    func showWindow() {
        guard let window = clockWindow else { return }
        window.orderFrontRegardless()
        
        // 通知窗口管理器创建窗口
        if let contentView = hostingView {
            viewModel.windowManager.createClockWindow(contentView: contentView)
        }
    }
    
    /// 隐藏窗口
    func hideWindow() {
        clockWindow?.orderOut(nil)
    }
    
    /// 清理资源
    func cleanup() {
        cancellables.removeAll()
        clockWindow?.close()
        clockWindow = nil
        hostingView = nil
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func setupWindow() {
        // 创建时钟视图
        let clockView = ClockView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: clockView)
        
        guard let contentView = hostingView else { return }
        
        // 创建窗口
        clockWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = clockWindow else { return }
        
        // 窗口基础设置
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true
        window.delegate = self
        
        // 窗口层级设置 - 使其在全屏应用上方可见，使用安全的层级值
        window.level = .statusBar
        
        // 空间行为设置 - 支持所有空间和全屏辅助
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        
        // 设置内容视图
        window.contentView = contentView
        
        // 设置窗口大小自适应内容
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.setContentHuggingPriority(.required, for: .horizontal)
        contentView.setContentHuggingPriority(.required, for: .vertical)
        
        // 更新窗口位置
        updateWindowPosition()
        
        // 设置初始可见性
        updateWindowVisibility()
    }
    
    @MainActor
    private func setupBindings() {
        // 监听可见性变化
        viewModel.$isVisible
            .sink { [weak self] isVisible in
                Task { @MainActor in
                    self?.updateWindowVisibility()
                }
            }
            .store(in: &cancellables)
        
        // 监听窗口配置变化
        viewModel.windowManager.$windowConfig
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateWindowProperties()
                    self?.updateWindowPosition()
                }
            }
            .store(in: &cancellables)
        
        // 监听时间更新来调整窗口大小
        viewModel.$currentTime
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateWindowSize()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func updateWindowVisibility() {
        guard let window = clockWindow else { return }
        
        if viewModel.isVisible {
            window.orderFrontRegardless()
        } else {
            window.orderOut(nil)
        }
    }
    
    @MainActor
    private func updateWindowProperties() {
        guard let window = clockWindow else { return }
        
        let config = viewModel.windowManager.windowConfig
        
        // 更新点击穿透
        window.ignoresMouseEvents = config.allowsClickThrough
        
        // 更新窗口是否可移动
        window.isMovable = !config.isLocked
        
        // 更新截图排除设置
        if viewModel.preferencesManager.behaviorConfig.hideFromScreenshots {
            window.sharingType = .none
        } else {
            window.sharingType = .readOnly
        }
    }
    
    @MainActor
    private func updateWindowPosition() {
        guard let window = clockWindow,
              let screen = getTargetScreen() else { return }
        
        let config = viewModel.windowManager.windowConfig
        let windowSize = window.frame.size
        let screenFrame = screen.visibleFrame
        let safeAreaInsets = getSafeAreaInsets(for: screen)
        
        let position: CGPoint
        
        switch config.position {
        case .topLeft:
            position = CGPoint(
                x: screenFrame.minX + config.margin + safeAreaInsets.left,
                y: screenFrame.maxY - windowSize.height - config.margin - safeAreaInsets.top
            )
        case .topRight:
            position = CGPoint(
                x: screenFrame.maxX - windowSize.width - config.margin - safeAreaInsets.right,
                y: screenFrame.maxY - windowSize.height - config.margin - safeAreaInsets.top
            )
        case .bottomLeft:
            position = CGPoint(
                x: screenFrame.minX + config.margin + safeAreaInsets.left,
                y: screenFrame.minY + config.margin + safeAreaInsets.bottom
            )
        case .bottomRight:
            position = CGPoint(
                x: screenFrame.maxX - windowSize.width - config.margin - safeAreaInsets.right,
                y: screenFrame.minY + config.margin + safeAreaInsets.bottom
            )
        case .topCenter:
            position = CGPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.maxY - windowSize.height - config.margin - safeAreaInsets.top
            )
        case .bottomCenter:
            position = CGPoint(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.minY + config.margin + safeAreaInsets.bottom
            )
        case .custom:
            position = config.customPoint ?? CGPoint(x: screenFrame.midX, y: screenFrame.midY)
        }
        
        window.setFrameOrigin(position)
    }
    
    @MainActor
    private func updateWindowSize() {
        guard let window = clockWindow,
              let contentView = hostingView else { return }
        
        // 获取内容的适合大小
        let fittingSize = contentView.fittingSize
        let newSize = NSSize(
            width: max(fittingSize.width, 100), // 最小宽度
            height: max(fittingSize.height, 30)  // 最小高度
        )
        
        // 只有在大小发生显著变化时才更新
        let currentSize = window.frame.size
        if abs(currentSize.width - newSize.width) > 5 || abs(currentSize.height - newSize.height) > 5 {
            let currentOrigin = window.frame.origin
            window.setFrame(NSRect(origin: currentOrigin, size: newSize), display: true)
            
            // 重新调整位置以保持对齐
            updateWindowPosition()
        }
    }
    
    @MainActor
    private func getTargetScreen() -> NSScreen? {
        // 根据显示器配置获取目标屏幕
        let displayConfig = viewModel.preferencesManager.displayConfig
        let targetDisplay = viewModel.displayManager.getBestDisplay(for: displayConfig)
        return targetDisplay?.screen ?? NSScreen.main
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

// MARK: - NSWindowDelegate

extension ClockWindowController: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        // 窗口移动后保存位置（如果是自由拖拽）
        guard let window = clockWindow,
              !viewModel.isLocked else { return }
        
        let newPosition = window.frame.origin
        let currentConfig = viewModel.preferencesManager.windowConfig
        
        let newConfig = WindowConfig(
            position: .custom,
            customPoint: newPosition,
            margin: currentConfig.margin,
            isLocked: currentConfig.isLocked,
            allowsClickThrough: currentConfig.allowsClickThrough
        )
        
        viewModel.preferencesManager.windowConfig = newConfig
    }
    
    func windowWillClose(_ notification: Notification) {
        // 窗口将要关闭时的处理
        cleanup()
    }
}