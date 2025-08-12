//
//  ConfigurationHelper.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation
import CoreGraphics

/// 配置更新助手，用于减少重复的配置更新代码
struct ConfigurationHelper {
    
    // MARK: - 外观配置更新
    
    /// 更新外观配置的通用方法
    static func updateAppearanceConfig(
        _ current: AppearanceConfig,
        fontSize: CGFloat? = nil,
        fontWeight: FontWeightOption? = nil,
        fontDesign: FontDesignOption? = nil,
        opacity: Double? = nil,
        backgroundColor: String? = nil,
        cornerRadius: CGFloat? = nil,
        useBlurBackground: Bool? = nil,
        enableShadow: Bool? = nil,
        shadowRadius: CGFloat? = nil,
        textColor: String? = nil,
        useSystemColors: Bool? = nil
    ) -> AppearanceConfig {
        return AppearanceConfig(
            fontSize: fontSize ?? current.fontSize,
            fontWeight: fontWeight ?? current.fontWeight,
            fontDesign: fontDesign ?? current.fontDesign,
            opacity: opacity ?? current.opacity,
            backgroundColor: backgroundColor ?? current.backgroundColor,
            cornerRadius: cornerRadius ?? current.cornerRadius,
            useBlurBackground: useBlurBackground ?? current.useBlurBackground,
            enableShadow: enableShadow ?? current.enableShadow,
            shadowRadius: shadowRadius ?? current.shadowRadius,
            textColor: textColor ?? current.textColor,
            useSystemColors: useSystemColors ?? current.useSystemColors
        )
    }
    
    // MARK: - 时间格式配置更新
    
    /// 更新时间格式配置的通用方法
    static func updateTimeFormat(
        _ current: TimeFormat,
        is24Hour: Bool? = nil,
        showSeconds: Bool? = nil,
        showDate: Bool? = nil,
        showWeekday: Bool? = nil,
        dateFormat: DateFormatOption? = nil,
        customSeparator: String? = nil,
        useLocalizedFormat: Bool? = nil
    ) -> TimeFormat {
        return TimeFormat(
            is24Hour: is24Hour ?? current.is24Hour,
            showSeconds: showSeconds ?? current.showSeconds,
            showDate: showDate ?? current.showDate,
            showWeekday: showWeekday ?? current.showWeekday,
            dateFormat: dateFormat ?? current.dateFormat,
            customSeparator: customSeparator ?? current.customSeparator,
            useLocalizedFormat: useLocalizedFormat ?? current.useLocalizedFormat
        )
    }
    
    // MARK: - 窗口配置更新
    
    /// 更新窗口配置的通用方法
    static func updateWindowConfig(
        _ current: WindowConfig,
        position: WindowPosition? = nil,
        customPoint: CGPoint? = nil,
        margin: CGFloat? = nil,
        isLocked: Bool? = nil,
        allowsClickThrough: Bool? = nil,
        enableDragging: Bool? = nil,
        enableSnapping: Bool? = nil,
        snapDistance: CGFloat? = nil,
        rememberPosition: Bool? = nil,
        respectSafeArea: Bool? = nil,
        lastSavedPosition: CGPoint?? = nil
    ) -> WindowConfig {
        return WindowConfig(
            position: position ?? current.position,
            customPoint: customPoint ?? current.customPoint,
            margin: margin ?? current.margin,
            isLocked: isLocked ?? current.isLocked,
            allowsClickThrough: allowsClickThrough ?? current.allowsClickThrough,
            enableDragging: enableDragging ?? current.enableDragging,
            enableSnapping: enableSnapping ?? current.enableSnapping,
            snapDistance: snapDistance ?? current.snapDistance,
            rememberPosition: rememberPosition ?? current.rememberPosition,
            respectSafeArea: respectSafeArea ?? current.respectSafeArea,
            lastSavedPosition: lastSavedPosition ?? current.lastSavedPosition
        )
    }
    
    // MARK: - 行为配置更新
    
    /// 更新行为配置的通用方法
    static func updateBehaviorConfig(
        _ current: BehaviorConfig,
        launchAtLogin: Bool? = nil,
        hideFromDock: Bool? = nil,
        hideFromScreenshots: Bool? = nil,
        enableAutoHide: Bool? = nil,
        autoHideDelay: TimeInterval? = nil,
        windowLevel: WindowLevelType? = nil,
        showInFullScreen: Bool? = nil,
        showInAllSpaces: Bool? = nil,
        stayOnTop: Bool? = nil
    ) -> BehaviorConfig {
        return BehaviorConfig(
            launchAtLogin: launchAtLogin ?? current.launchAtLogin,
            hideFromDock: hideFromDock ?? current.hideFromDock,
            hideFromScreenshots: hideFromScreenshots ?? current.hideFromScreenshots,
            enableAutoHide: enableAutoHide ?? current.enableAutoHide,
            autoHideDelay: autoHideDelay ?? current.autoHideDelay,
            windowLevel: windowLevel ?? current.windowLevel,
            showInFullScreen: showInFullScreen ?? current.showInFullScreen,
            showInAllSpaces: showInAllSpaces ?? current.showInAllSpaces,
            stayOnTop: stayOnTop ?? current.stayOnTop
        )
    }
    
    // MARK: - 显示器配置更新
    
    /// 更新显示器配置的通用方法
    static func updateDisplayConfig(
        _ current: DisplayConfig,
        targetDisplayUUID: String? = nil,
        showOnAllDisplays: Bool? = nil,
        followMainDisplay: Bool? = nil
    ) -> DisplayConfig {
        return DisplayConfig(
            targetDisplayUUID: targetDisplayUUID ?? current.targetDisplayUUID,
            showOnAllDisplays: showOnAllDisplays ?? current.showOnAllDisplays,
            followMainDisplay: followMainDisplay ?? current.followMainDisplay
        )
    }
    
    // MARK: - 高级配置更新
    
    /// 更新高级配置的通用方法
    static func updateAdvancedConfig(
        _ current: AdvancedConfig,
        enableDebugMode: Bool? = nil,
        enableLogging: Bool? = nil,
        refreshRate: Int? = nil,
        energySaveMode: Bool? = nil
    ) -> AdvancedConfig {
        return AdvancedConfig(
            enableDebugMode: enableDebugMode ?? current.enableDebugMode,
            enableLogging: enableLogging ?? current.enableLogging,
            refreshRate: refreshRate ?? current.refreshRate,
            energySaveMode: energySaveMode ?? current.energySaveMode
        )
    }
}

/// 配置验证助手
struct ConfigurationValidator {
    
    /// 验证字体大小是否在有效范围内
    static func isValidFontSize(_ size: CGFloat) -> Bool {
        return size >= AppConstants.UI.fontSizeMin && size <= AppConstants.UI.fontSizeMax
    }
    
    /// 验证透明度是否在有效范围内
    static func isValidOpacity(_ opacity: Double) -> Bool {
        return opacity >= AppConstants.UI.opacityMin && opacity <= AppConstants.UI.opacityMax
    }
    
    /// 验证吸附距离是否在有效范围内
    static func isValidSnapDistance(_ distance: CGFloat) -> Bool {
        return distance >= AppConstants.DragAndSnap.snapDistanceMin && distance <= AppConstants.DragAndSnap.snapDistanceMax
    }
    
    /// 验证刷新率是否有效
    static func isValidRefreshRate(_ rate: Int) -> Bool {
        return rate > 0 && rate <= 120
    }
}