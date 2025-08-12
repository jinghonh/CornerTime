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
    
    // 拖拽相关属性
    private var dragStartPoint: CGPoint?
    private var isDragging: Bool = false
    
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
        
        // 直接显示窗口，不重复创建
        window.orderFrontRegardless()
        
        // 确保窗口可见
        window.makeKeyAndOrderFront(nil)
        
        // 打印调试信息
        print("时钟窗口已显示 - 位置: \(window.frame), 层级: \(window.level.rawValue)")
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
        print("🏗️ 开始设置时钟窗口...")
        
        // 创建时钟视图
        let clockView = ClockView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: clockView)
        
        // 设置拖拽事件处理
        if let contentView = hostingView {
            setupDragHandling(for: contentView)
        }
        
        guard let contentView = hostingView else { 
            print("❌ 错误：无法创建hosting view")
            return 
        }
        
        print("✅ SwiftUI视图创建成功")
        
        // 创建窗口
        clockWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = clockWindow else { 
            print("❌ 错误：无法创建NSWindow")
            return 
        }
        
        print("✅ NSWindow创建成功")
        
        // 窗口基础设置
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true
        window.delegate = self
        
        // 动态设置窗口层级和行为（基于当前配置和状态）
        let behaviorConfig = viewModel.preferencesManager.behaviorConfig
        viewModel.windowManager.updateWindowLevelAndBehavior(
            window: window,
            behaviorConfig: behaviorConfig,
            spaceManager: viewModel.spaceManager
        )
        
        // 设置内容视图
        window.contentView = contentView
        print("✅ 内容视图设置完成")
        
        // 设置窗口大小自适应内容
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.setContentHuggingPriority(.required, for: .horizontal)
        contentView.setContentHuggingPriority(.required, for: .vertical)
        
        // 更新窗口位置
        updateWindowPosition()
        
        // 设置初始可见性
        updateWindowVisibility()
        
        print("🎉 时钟窗口设置完成！")
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
        
        // 更新点击穿透（但拖拽时需要接收鼠标事件）
        window.ignoresMouseEvents = config.allowsClickThrough && !config.enableDragging
        
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
        
        // 确保位置在屏幕可见范围内
        let safePosition = ensurePositionInBounds(position, windowSize: windowSize, screenFrame: screenFrame)
        
        // 临时禁用窗口委托，防止programmatic移动触发windowDidMove
        let originalDelegate = window.delegate
        window.delegate = nil
        
        window.setFrameOrigin(safePosition)
        
        // 恢复窗口委托
        window.delegate = originalDelegate
        
        print("📍 窗口位置更新: \(safePosition), 配置: \(config.position.displayName)")
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
    
    // MARK: - Drag Support
    
    /// 设置拖拽事件处理
    private func setupDragHandling(for view: NSView) {
        // 创建拖拽识别手势
        let dragGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        
        // 配置手势识别器
        dragGesture.buttonMask = 0x1 // 只响应鼠标左键
        
        view.addGestureRecognizer(dragGesture)
        print("🫱 已为视图添加拖拽手势识别器: \(view.className)")
    }
    
    /// 处理拖拽手势
    @MainActor
    @objc private func handlePanGesture(_ gesture: NSPanGestureRecognizer) {
        guard let window = clockWindow else { 
            print("❌ 拖拽手势：窗口不存在")
            return 
        }
        
        let config = viewModel.windowManager.windowConfig
        
        // 检查是否允许拖拽
        guard config.enableDragging && !config.isLocked else { 
            print("❌ 拖拽手势：拖拽被禁用或窗口被锁定 (enableDragging: \(config.enableDragging), isLocked: \(config.isLocked))")
            return 
        }
        
        print("🫱 拖拽手势状态: \(gesture.state.rawValue)")
        
        let locationInWindow = gesture.location(in: window.contentView)
        let locationOnScreen = window.convertPoint(toScreen: locationInWindow)
        
        switch gesture.state {
        case .began:
            handleDragStart(at: locationOnScreen)
            
        case .changed:
            handleDragMove(to: locationOnScreen)
            
        case .ended, .cancelled, .failed:
            handleDragEnd()
            
        default:
            break
        }
    }
    
    /// 开始拖拽
    @MainActor
    private func handleDragStart(at point: CGPoint) {
        dragStartPoint = point
        isDragging = true
        
        // 通知窗口管理器开始拖拽
        viewModel.windowManager.handleWindowDrag(event: .started(point))
        
        print("🫸 开始拖拽时钟窗口")
    }
    
    /// 拖拽移动
    @MainActor
    private func handleDragMove(to point: CGPoint) {
        guard isDragging else { return }
        
        // 通知窗口管理器处理拖拽移动
        viewModel.windowManager.handleWindowDrag(event: .moved(point))
    }
    
    /// 结束拖拽
    @MainActor
    private func handleDragEnd() {
        guard isDragging else { return }
        
        isDragging = false
        dragStartPoint = nil
        
        // 通知窗口管理器结束拖拽
        viewModel.windowManager.handleWindowDrag(event: .ended)
        
        print("🫷 结束拖拽时钟窗口")
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
            // 临时禁用窗口委托，防止大小调整触发windowDidMove
            let originalDelegate = window.delegate
            window.delegate = nil
            
            let currentOrigin = window.frame.origin
            window.setFrame(NSRect(origin: currentOrigin, size: newSize), display: true)
            
            // 恢复窗口委托
            window.delegate = originalDelegate
            
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
            allowsClickThrough: currentConfig.allowsClickThrough,
            enableDragging: currentConfig.enableDragging,
            enableSnapping: currentConfig.enableSnapping,
            snapDistance: currentConfig.snapDistance,
            rememberPosition: currentConfig.rememberPosition,
            respectSafeArea: currentConfig.respectSafeArea,
            lastSavedPosition: currentConfig.lastSavedPosition
        )
        
        viewModel.preferencesManager.windowConfig = newConfig
    }
    
    func windowWillClose(_ notification: Notification) {
        // 窗口将要关闭时的处理
        cleanup()
    }
}