//
//  PreferencesManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation
import Combine

/// 外观配置
struct AppearanceConfig: Codable {
    let fontSize: CGFloat
    let fontWeight: String
    let opacity: Double
    let backgroundColor: String
    let cornerRadius: CGFloat
    let useBlurBackground: Bool
    
    init(fontSize: CGFloat = 14,
         fontWeight: String = "regular",
         opacity: Double = 1.0,
         backgroundColor: String = "clear",
         cornerRadius: CGFloat = 4,
         useBlurBackground: Bool = false) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.opacity = opacity
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.useBlurBackground = useBlurBackground
    }
}

/// 行为配置
struct BehaviorConfig: Codable {
    let launchAtLogin: Bool
    let hideFromDock: Bool
    let hideFromScreenshots: Bool
    let enableAutoHide: Bool
    let autoHideDelay: TimeInterval
    
    init(launchAtLogin: Bool = false,
         hideFromDock: Bool = true,
         hideFromScreenshots: Bool = false,
         enableAutoHide: Bool = false,
         autoHideDelay: TimeInterval = 5.0) {
        self.launchAtLogin = launchAtLogin
        self.hideFromDock = hideFromDock
        self.hideFromScreenshots = hideFromScreenshots
        self.enableAutoHide = enableAutoHide
        self.autoHideDelay = autoHideDelay
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
    
    // 配置键名
    private struct Keys {
        static let timeFormat = "com.cornertime.app.timeFormat"
        static let windowConfig = "com.cornertime.app.windowConfig"
        static let appearanceConfig = "com.cornertime.app.appearanceConfig"
        static let behaviorConfig = "com.cornertime.app.behaviorConfig"
        static let displayConfig = "com.cornertime.app.displayConfig"
        static let advancedConfig = "com.cornertime.app.advancedConfig"
    }
    
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
        // 此处需要实现配置导入逻辑
        // 暂时返回 false，后续实现
        return false
    }
    
    // MARK: - Private Methods
    
    private func loadConfigurations() {
        // 加载时间格式配置
        if let data = userDefaults.data(forKey: Keys.timeFormat),
           let decoded = try? JSONDecoder().decode(TimeFormat.self, from: data) {
            timeFormat = decoded
        }
        
        // 加载窗口配置
        if let data = userDefaults.data(forKey: Keys.windowConfig),
           let decoded = try? JSONDecoder().decode(WindowConfig.self, from: data) {
            windowConfig = decoded
        }
        
        // 加载外观配置
        if let data = userDefaults.data(forKey: Keys.appearanceConfig),
           let decoded = try? JSONDecoder().decode(AppearanceConfig.self, from: data) {
            appearanceConfig = decoded
        }
        
        // 加载行为配置
        if let data = userDefaults.data(forKey: Keys.behaviorConfig),
           let decoded = try? JSONDecoder().decode(BehaviorConfig.self, from: data) {
            behaviorConfig = decoded
        }
        
        // 加载显示器配置
        if let data = userDefaults.data(forKey: Keys.displayConfig),
           let decoded = try? JSONDecoder().decode(DisplayConfig.self, from: data) {
            displayConfig = decoded
        }
        
        // 加载高级配置
        if let data = userDefaults.data(forKey: Keys.advancedConfig),
           let decoded = try? JSONDecoder().decode(AdvancedConfig.self, from: data) {
            advancedConfig = decoded
        }
    }
    
    private func setupObservers() {
        // 监听配置变化并自动保存
        $timeFormat
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: Keys.timeFormat)
            }
            .store(in: &cancellables)
        
        $windowConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: Keys.windowConfig)
            }
            .store(in: &cancellables)
        
        $appearanceConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: Keys.appearanceConfig)
            }
            .store(in: &cancellables)
        
        $behaviorConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: Keys.behaviorConfig)
            }
            .store(in: &cancellables)
        
        $displayConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: Keys.displayConfig)
            }
            .store(in: &cancellables)
        
        $advancedConfig
            .dropFirst()
            .sink { [weak self] config in
                self?.saveConfiguration(config, key: Keys.advancedConfig)
            }
            .store(in: &cancellables)
    }
    
    private func saveConfiguration<T: Codable>(_ config: T, key: String) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    private func saveAllConfigurations() {
        saveConfiguration(timeFormat, key: Keys.timeFormat)
        saveConfiguration(windowConfig, key: Keys.windowConfig)
        saveConfiguration(appearanceConfig, key: Keys.appearanceConfig)
        saveConfiguration(behaviorConfig, key: Keys.behaviorConfig)
        saveConfiguration(displayConfig, key: Keys.displayConfig)
        saveConfiguration(advancedConfig, key: Keys.advancedConfig)
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