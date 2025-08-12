//
//  PreferencesManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation
import Combine
import AppKit

/// 字体粗细选项
enum FontWeightOption: String, Codable, CaseIterable {
    case ultraLight = "ultraLight"
    case light = "light"
    case regular = "regular"
    case medium = "medium"
    case semibold = "semibold"
    case bold = "bold"
    case heavy = "heavy"
    case black = "black"
    
    var displayName: String {
        switch self {
        case .ultraLight: return "极细"
        case .light: return "细"
        case .regular: return "常规"
        case .medium: return "中等"
        case .semibold: return "半粗"
        case .bold: return "粗体"
        case .heavy: return "重"
        case .black: return "黑体"
        }
    }
    
    var fontWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

/// 字体设计选项
enum FontDesignOption: String, Codable, CaseIterable {
    case `default` = "default"
    case monospaced = "monospaced"
    case rounded = "rounded"
    case serif = "serif"
    
    var displayName: String {
        switch self {
        case .default: return "默认"
        case .monospaced: return "等宽"
        case .rounded: return "圆润"
        case .serif: return "衬线"
        }
    }
}

/// 外观配置
struct AppearanceConfig: Codable {
    let fontSize: CGFloat
    let fontWeight: FontWeightOption
    let fontDesign: FontDesignOption
    let opacity: Double
    let backgroundColor: String
    let cornerRadius: CGFloat
    let useBlurBackground: Bool
    let enableShadow: Bool
    let shadowRadius: CGFloat
    let textColor: String
    let useSystemColors: Bool
    
    init(fontSize: CGFloat = AppConstants.UI.fontSizeDefault,
         fontWeight: FontWeightOption = .medium,
         fontDesign: FontDesignOption = .monospaced,
         opacity: Double = AppConstants.UI.opacityDefault,
         backgroundColor: String = "clear",
         cornerRadius: CGFloat = AppConstants.UI.cornerRadiusDefault,
         useBlurBackground: Bool = false,
         enableShadow: Bool = true,
         shadowRadius: CGFloat = AppConstants.UI.shadowRadiusDefault,
         textColor: String = "primary",
         useSystemColors: Bool = true) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.opacity = opacity
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.useBlurBackground = useBlurBackground
        self.enableShadow = enableShadow
        self.shadowRadius = shadowRadius
        self.textColor = textColor
        self.useSystemColors = useSystemColors
    }
}

/// 窗口层级类型
enum WindowLevelType: String, Codable, CaseIterable {
    case normal = "normal"
    case floating = "floating"
    case statusBar = "statusBar"
    case modalPanel = "modalPanel"
    case popupMenu = "popupMenu"
    
    var displayName: String {
        switch self {
        case .normal: return "普通"
        case .floating: return "浮动"
        case .statusBar: return "状态栏"
        case .modalPanel: return "模态面板"
        case .popupMenu: return "弹出菜单"
        }
    }
    
    var nsWindowLevel: NSWindow.Level {
        switch self {
        case .normal: return .normal
        case .floating: return .floating
        case .statusBar: return .statusBar
        case .modalPanel: return .modalPanel
        case .popupMenu: return .popUpMenu
        }
    }
}

/// 行为配置
struct BehaviorConfig: Codable {
    let launchAtLogin: Bool
    let hideFromDock: Bool
    let hideFromScreenshots: Bool
    let enableAutoHide: Bool
    let autoHideDelay: TimeInterval
    let windowLevel: WindowLevelType
    let showInFullScreen: Bool
    let showInAllSpaces: Bool
    let stayOnTop: Bool
    
    init(launchAtLogin: Bool = false,
         hideFromDock: Bool = true,
         hideFromScreenshots: Bool = false,
         enableAutoHide: Bool = false,
         autoHideDelay: TimeInterval = 5.0,
         windowLevel: WindowLevelType = .statusBar,
         showInFullScreen: Bool = true,
         showInAllSpaces: Bool = true,
         stayOnTop: Bool = true) {
        self.launchAtLogin = launchAtLogin
        self.hideFromDock = hideFromDock
        self.hideFromScreenshots = hideFromScreenshots
        self.enableAutoHide = enableAutoHide
        self.autoHideDelay = autoHideDelay
        self.windowLevel = windowLevel
        self.showInFullScreen = showInFullScreen
        self.showInAllSpaces = showInAllSpaces
        self.stayOnTop = stayOnTop
    }
}

/// 显示器配置
struct DisplayConfig: Codable {
    let targetDisplayUUID: String?
    let showOnAllDisplays: Bool
    let followMainDisplay: Bool
    
    init(targetDisplayUUID: String? = nil,
         showOnAllDisplays: Bool = false,
         followMainDisplay: Bool = true) {
        self.targetDisplayUUID = targetDisplayUUID
        self.showOnAllDisplays = showOnAllDisplays
        self.followMainDisplay = followMainDisplay
    }
}

/// 高级配置
struct AdvancedConfig: Codable {
    let enableDebugMode: Bool
    let enableLogging: Bool
    let refreshRate: Int
    let energySaveMode: Bool
    
    init(enableDebugMode: Bool = false,
         enableLogging: Bool = false,
         refreshRate: Int = 60,
         energySaveMode: Bool = true) {
        self.enableDebugMode = enableDebugMode
        self.enableLogging = enableLogging
        self.refreshRate = refreshRate
        self.energySaveMode = energySaveMode
    }
}

/// 应用偏好设置管理器
@MainActor
class PreferencesManager: ObservableObject {
    // MARK: - Published Properties
    @Published var timeFormat: TimeFormat = TimeFormat()
    @Published var windowConfig: WindowConfig = WindowConfig()
    @Published var appearanceConfig: AppearanceConfig = AppearanceConfig()
    @Published var behaviorConfig: BehaviorConfig = BehaviorConfig()
    @Published var displayConfig: DisplayConfig = DisplayConfig()
    @Published var advancedConfig: AdvancedConfig = AdvancedConfig()
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Initialization
    init() {
        loadConfigurations()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// 重置所有设置为默认值
    func resetToDefaults() {
        timeFormat = TimeFormat()
        windowConfig = WindowConfig()
        appearanceConfig = AppearanceConfig()
        behaviorConfig = BehaviorConfig()
        displayConfig = DisplayConfig()
        advancedConfig = AdvancedConfig()
        
        saveAllConfigurations()
    }
    
    /// 导出配置到文件
    func exportConfiguration() -> Data? {
        let configuration = ConfigurationBundle(
            timeFormat: timeFormat,
            windowConfig: windowConfig,
            appearanceConfig: appearanceConfig,
            behaviorConfig: behaviorConfig,
            displayConfig: displayConfig,
            advancedConfig: advancedConfig
        )
        
        return try? JSONEncoder().encode(configuration)
    }
    
    /// 从文件导入配置
    func importConfiguration(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(ConfigurationBundle.self, from: data)
            
            // 验证配置版本兼容性
            guard isConfigurationCompatible(configuration) else {
                print("配置版本不兼容")
                return false
            }
            
            // 导入配置
            timeFormat = configuration.timeFormat
            windowConfig = configuration.windowConfig
            appearanceConfig = configuration.appearanceConfig
            behaviorConfig = configuration.behaviorConfig
            displayConfig = configuration.displayConfig
            advancedConfig = configuration.advancedConfig
            
            // 手动触发保存
            saveAllConfigurations()
            
            print("配置导入成功")
            return true
            
        } catch {
            print("配置导入失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 检查配置兼容性
    private func isConfigurationCompatible(_ configuration: ConfigurationBundle) -> Bool {
        // 基本的兼容性检查
        // 可以根据需要添加更多验证逻辑
        return true
    }
    
    // MARK: - Private Methods
    
    private func loadConfigurations() {
        // 加载时间格式配置
        if let data = userDefaults.data(forKey: ConfigKeys.timeFormat),
           let decoded = try? JSONDecoder().decode(TimeFormat.self, from: data) {
            timeFormat = decoded
        }
        
        // 加载窗口配置
        if let data = userDefaults.data(forKey: ConfigKeys.windowConfig),
           let decoded = try? JSONDecoder().decode(WindowConfig.self, from: data) {
            windowConfig = decoded
        }
        
        // 加载外观配置
        if let data = userDefaults.data(forKey: ConfigKeys.appearanceConfig),
           let decoded = try? JSONDecoder().decode(AppearanceConfig.self, from: data) {
            appearanceConfig = decoded
        }
        
        // 加载行为配置
        if let data = userDefaults.data(forKey: ConfigKeys.behaviorConfig),
           let decoded = try? JSONDecoder().decode(BehaviorConfig.self, from: data) {
            behaviorConfig = decoded
        }
        
        // 加载显示器配置
        if let data = userDefaults.data(forKey: ConfigKeys.displayConfig),
           let decoded = try? JSONDecoder().decode(DisplayConfig.self, from: data) {
            displayConfig = decoded
        }
        
        // 加载高级配置
        if let data = userDefaults.data(forKey: ConfigKeys.advancedConfig),
           let decoded = try? JSONDecoder().decode(AdvancedConfig.self, from: data) {
            advancedConfig = decoded
        }
    }
    
    private func setupObservers() {
        // 监听配置变化并自动保存
        $timeFormat
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: ConfigKeys.timeFormat)
            }
            .store(in: &cancellables)
        
        $windowConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: ConfigKeys.windowConfig)
            }
            .store(in: &cancellables)
        
        $appearanceConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: ConfigKeys.appearanceConfig)
            }
            .store(in: &cancellables)
        
        $behaviorConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: ConfigKeys.behaviorConfig)
            }
            .store(in: &cancellables)
        
        $displayConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: ConfigKeys.displayConfig)
            }
            .store(in: &cancellables)
        
        $advancedConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: ConfigKeys.advancedConfig)
            }
            .store(in: &cancellables)
    }
    
    private func saveConfiguration<T: Codable>(_ config: T, key: String) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    private func saveAllConfigurations() {
        saveConfiguration(timeFormat, key: ConfigKeys.timeFormat)
        saveConfiguration(windowConfig, key: ConfigKeys.windowConfig)
        saveConfiguration(appearanceConfig, key: ConfigKeys.appearanceConfig)
        saveConfiguration(behaviorConfig, key: ConfigKeys.behaviorConfig)
        saveConfiguration(displayConfig, key: ConfigKeys.displayConfig)
        saveConfiguration(advancedConfig, key: ConfigKeys.advancedConfig)
    }
    
    /// 更新窗口配置
    @MainActor
    func updateWindowConfig(_ newConfig: WindowConfig) {
        windowConfig = newConfig
        objectWillChange.send()
    }
}

// MARK: - Configuration Bundle

/// 配置导出/导入的包装结构
struct ConfigurationBundle: Codable {
    let timeFormat: TimeFormat
    let windowConfig: WindowConfig
    let appearanceConfig: AppearanceConfig
    let behaviorConfig: BehaviorConfig
    let displayConfig: DisplayConfig
    let advancedConfig: AdvancedConfig
}