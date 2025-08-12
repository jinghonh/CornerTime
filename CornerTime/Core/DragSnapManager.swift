//
//  DragSnapManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import Foundation

/// 拖拽状态
enum DragState {
    case idle
    case dragging(startPoint: CGPoint, initialWindowFrame: NSRect)
}

/// 吸附边缘类型
enum SnapEdge {
    case top
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case none
}

/// 拖拽和吸附管理器
@MainActor
class DragSnapManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isDragging: Bool = false
    @Published var currentSnapEdge: SnapEdge = .none
    
    // MARK: - Private Properties
    private var dragState: DragState = .idle
    private weak var targetWindow: NSWindow?
    private var config: WindowConfig
    
    // MARK: - Initialization
    init(config: WindowConfig) {
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// 设置目标窗口
    func setTargetWindow(_ window: NSWindow) {
        targetWindow = window
    }
    
    /// 更新配置
    func updateConfig(_ newConfig: WindowConfig) {
        config = newConfig
    }
    
    /// 开始拖拽
    func startDragging(at point: CGPoint) {
        guard let window = targetWindow,
              config.enableDragging && !config.isLocked else { return }
        
        let windowFrame = window.frame
        dragState = .dragging(startPoint: point, initialWindowFrame: windowFrame)
        isDragging = true
        
        print("🫸 开始拖拽窗口，起始点: \(point)")
    }
    
    /// 处理拖拽移动
    func handleDragMove(to point: CGPoint) {
        guard case let .dragging(startPoint, initialFrame) = dragState,
              let window = targetWindow else { 
            print("❌ 拖拽状态无效或窗口不存在")
            return 
        }
        
        // 计算新位置
        let deltaX = point.x - startPoint.x
        let deltaY = point.y - startPoint.y
        let newOrigin = CGPoint(
            x: initialFrame.origin.x + deltaX,
            y: initialFrame.origin.y + deltaY
        )
        
        print("🔄 拖拽移动: 当前点=\(point), 起始点=\(startPoint), 偏移=(\(deltaX), \(deltaY)), 新位置=\(newOrigin)")
        
        // 应用吸附
        let snappedPosition = applySnapping(to: newOrigin, windowSize: window.frame.size)
        
        // 更新窗口位置
        window.setFrameOrigin(snappedPosition)
    }
    
    /// 结束拖拽
    func endDragging() {
        dragState = .idle
        isDragging = false
        currentSnapEdge = .none
        
        // 如果启用位置记忆，保存当前位置
        if config.rememberPosition, let window = targetWindow {
            saveCurrentPosition(window.frame.origin)
        }
        
        print("🫷 结束拖拽窗口")
    }
    
    /// 获取安全区域边界
    func getSafeAreaBounds(for screen: NSScreen) -> NSRect {
        guard config.respectSafeArea else {
            return screen.visibleFrame
        }
        
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        var safeFrame = visibleFrame
        
        // 检测刘海屏（MacBook Pro 的 notch）
        if hasNotch(screen: screen) {
            // 为刘海预留空间（通常在屏幕顶部中央）
            let notchHeight: CGFloat = 30 // 估计的刘海高度
            if safeFrame.maxY == screenFrame.maxY {
                safeFrame.size.height -= notchHeight
            }
        }
        
        // 为其他系统UI元素预留边距
        let systemMargin: CGFloat = 10
        safeFrame = safeFrame.insetBy(dx: systemMargin, dy: systemMargin)
        
        return safeFrame
    }
    
    // MARK: - Private Methods
    
    /// 应用吸附逻辑
    private func applySnapping(to position: CGPoint, windowSize: NSSize) -> CGPoint {
        guard config.enableSnapping else { return position }
        
        guard let screen = NSScreen.main else { return position }
        let safeFrame = getSafeAreaBounds(for: screen)
        let snapDistance = config.snapDistance
        
        var snappedPosition = position
        var snapEdge: SnapEdge = .none
        
        // 检查水平吸附
        let leftDistance = abs(position.x - safeFrame.minX)
        let rightDistance = abs(position.x + windowSize.width - safeFrame.maxX)
        let centerX = safeFrame.midX - windowSize.width / 2
        let centerXDistance = abs(position.x - centerX)
        
        if leftDistance <= snapDistance {
            snappedPosition.x = safeFrame.minX
            snapEdge = .left
        } else if rightDistance <= snapDistance {
            snappedPosition.x = safeFrame.maxX - windowSize.width
            snapEdge = .right
        } else if centerXDistance <= snapDistance {
            snappedPosition.x = centerX
        }
        
        // 检查垂直吸附
        let topDistance = abs(position.y + windowSize.height - safeFrame.maxY)
        let bottomDistance = abs(position.y - safeFrame.minY)
        let centerY = safeFrame.midY - windowSize.height / 2
        let centerYDistance = abs(position.y - centerY)
        
        if topDistance <= snapDistance {
            snappedPosition.y = safeFrame.maxY - windowSize.height
            snapEdge = (snapEdge == .left) ? .topLeft : (snapEdge == .right) ? .topRight : .top
        } else if bottomDistance <= snapDistance {
            snappedPosition.y = safeFrame.minY
            snapEdge = (snapEdge == .left) ? .bottomLeft : (snapEdge == .right) ? .bottomRight : .bottom
        } else if centerYDistance <= snapDistance {
            snappedPosition.y = centerY
        }
        
        // 更新当前吸附边缘
        currentSnapEdge = snapEdge
        
        // 如果发生吸附，输出调试信息
        if snappedPosition != position {
            print("🧲 窗口已吸附到: \(snapEdge), 位置: \(snappedPosition)")
        }
        
        return snappedPosition
    }
    
    /// 检测屏幕是否有刘海
    private func hasNotch(screen: NSScreen) -> Bool {
        // 基于屏幕分辨率和比例推测是否有刘海
        let screenSize = screen.frame.size
        let aspectRatio = screenSize.width / screenSize.height
        
        // MacBook Pro 14" 和 16" 的近似比例
        let macBookPro14Ratio: CGFloat = 1.556  // 3024 x 1964
        let macBookPro16Ratio: CGFloat = 1.556  // 3456 x 2234
        
        let tolerance: CGFloat = 0.05
        
        return abs(aspectRatio - macBookPro14Ratio) < tolerance ||
               abs(aspectRatio - macBookPro16Ratio) < tolerance
    }
    
    /// 保存当前位置
    private func saveCurrentPosition(_ position: CGPoint) {
        // 这里应该通知配置管理器保存位置
        // 我们需要在后面添加回调机制
        print("💾 保存窗口位置: \(position)")
    }
}

// MARK: - Extensions

extension DragSnapManager {
    /// 恢复保存的位置
    func restoreSavedPosition() -> CGPoint? {
        guard config.rememberPosition,
              let savedPosition = config.lastSavedPosition else {
            return nil
        }
        
        // 验证保存的位置是否仍然有效
        guard let screen = NSScreen.main else { return nil }
        let safeFrame = getSafeAreaBounds(for: screen)
        
        if safeFrame.contains(savedPosition) {
            print("📍 恢复保存的窗口位置: \(savedPosition)")
            return savedPosition
        } else {
            print("⚠️ 保存的位置已失效，使用默认位置")
            return nil
        }
    }
    
    /// 获取推荐的默认位置
    func getDefaultPosition(for windowSize: NSSize) -> CGPoint {
        guard let screen = NSScreen.main else {
            return CGPoint(x: 100, y: 100)
        }
        
        let safeFrame = getSafeAreaBounds(for: screen)
        
        switch config.position {
        case .topLeft:
            return CGPoint(x: safeFrame.minX, y: safeFrame.maxY - windowSize.height)
        case .topRight:
            return CGPoint(x: safeFrame.maxX - windowSize.width, y: safeFrame.maxY - windowSize.height)
        case .bottomLeft:
            return CGPoint(x: safeFrame.minX, y: safeFrame.minY)
        case .bottomRight:
            return CGPoint(x: safeFrame.maxX - windowSize.width, y: safeFrame.minY)
        case .topCenter:
            return CGPoint(x: safeFrame.midX - windowSize.width / 2, y: safeFrame.maxY - windowSize.height)
        case .bottomCenter:
            return CGPoint(x: safeFrame.midX - windowSize.width / 2, y: safeFrame.minY)
        case .custom:
            return config.customPoint ?? CGPoint(x: safeFrame.midX - windowSize.width / 2, y: safeFrame.midY - windowSize.height / 2)
        }
    }
}