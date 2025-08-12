//
//  AppConstants.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation
import CoreGraphics

/// 应用全局常量
struct AppConstants {
    
    // MARK: - UI常量
    struct UI {
        // 字体大小
        static let fontSizeMin: CGFloat = 12
        static let fontSizeMax: CGFloat = 48
        static let fontSizeStep: CGFloat = 2
        static let fontSizeDefault: CGFloat = 24
        static let fontSizePresets: [CGFloat] = [12, 14, 16, 18, 20, 24, 28, 32, 36, 42, 48]
        
        // 透明度
        static let opacityMin: Double = 0.3
        static let opacityMax: Double = 1.0
        static let opacityStep: Double = 0.1
        static let opacityDefault: Double = 1.0
        static let opacityPresets: [Double] = [0.3, 0.5, 0.7, 0.8, 0.9, 1.0]
        
        // 边距和圆角
        static let marginDefault: CGFloat = 20
        static let cornerRadiusDefault: CGFloat = 4
        static let shadowRadiusDefault: CGFloat = 1
        
        // 时钟窗口
        static let clockWindowWidth: CGFloat = 200
        static let clockWindowHeight: CGFloat = 60
        
        // 内边距
        static let clockPaddingTop: CGFloat = 4
        static let clockPaddingLeading: CGFloat = 8
        static let clockPaddingBottom: CGFloat = 4
        static let clockPaddingTrailing: CGFloat = 8
        
        // 指示器
        static let indicatorAutoHideDelay: TimeInterval = 3.0
        static let indicatorAnimationDuration: TimeInterval = 0.3
        static let indicatorOffset: CGFloat = 5
    }
    
    // MARK: - 定时器常量
    struct Timer {
        static let secondsInterval: TimeInterval = 1.0
        static let minutesInterval: TimeInterval = 60.0
    }
    
    // MARK: - 拖拽和吸附常量
    struct DragAndSnap {
        static let snapDistanceDefault: CGFloat = 20
        static let snapDistanceMin: CGFloat = 5
        static let snapDistanceMax: CGFloat = 50
    }
    
    // MARK: - 性能常量
    struct Performance {
        static let refreshRateDefault: Int = 60
        static let maxMemoryUsageMB: Int = 50
        static let maxCPUUsagePercent: Double = 2.0
    }
    
    // MARK: - 外观面板常量
    struct AppearancePanel {
        static let width: CGFloat = 350
        static let height: CGFloat = 500
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 10
        static let gridColumns: Int = 4
        static let gridSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 20
    }
    
    // MARK: - 动画常量
    struct Animation {
        static let standardDuration: TimeInterval = 0.3
        static let fastDuration: TimeInterval = 0.15
        static let slowDuration: TimeInterval = 0.5
    }
}

/// 应用配置键常量
struct ConfigKeys {
    static let timeFormat = "com.cornertime.app.timeFormat"
    static let windowConfig = "com.cornertime.app.windowConfig"
    static let appearanceConfig = "com.cornertime.app.appearanceConfig"
    static let behaviorConfig = "com.cornertime.app.behaviorConfig"
    static let displayConfig = "com.cornertime.app.displayConfig"
    static let advancedConfig = "com.cornertime.app.advancedConfig"
}