//
//  ClockCore.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation
import Combine

/// 日期格式选项
enum DateFormatOption: String, Codable, CaseIterable {
    case none = "none"
    case short = "short"        // 12/25
    case medium = "medium"      // 12月25日
    case long = "long"          // 2024年12月25日
    case weekday = "weekday"    // 星期三
    case full = "full"          // 2024年12月25日 星期三
    
    var displayName: String {
        switch self {
        case .none: return "不显示"
        case .short: return "简短 (12/25)"
        case .medium: return "中等 (12月25日)"
        case .long: return "完整 (2024年12月25日)"
        case .weekday: return "星期 (星期三)"
        case .full: return "详细 (2024年12月25日 星期三)"
        }
    }
}

/// 时间格式配置
struct TimeFormat: Codable {
    let is24Hour: Bool
    let showSeconds: Bool
    let showDate: Bool
    let showWeekday: Bool
    let dateFormat: DateFormatOption
    let customSeparator: String
    let useLocalizedFormat: Bool
    
    // 为了向后兼容，保留原有的初始化方法
    init(is24Hour: Bool = true, 
         showSeconds: Bool = true, 
         showDate: Bool = false, 
         showWeekday: Bool = false) {
        self.is24Hour = is24Hour
        self.showSeconds = showSeconds
        self.showDate = showDate
        self.showWeekday = showWeekday
        self.dateFormat = showDate ? (showWeekday ? .full : .medium) : .none
        self.customSeparator = ":"
        self.useLocalizedFormat = true
    }
    
    // 新的完整初始化方法
    init(is24Hour: Bool = true,
         showSeconds: Bool = true,
         showDate: Bool = false,
         showWeekday: Bool = false,
         dateFormat: DateFormatOption = .none,
         customSeparator: String = ":",
         useLocalizedFormat: Bool = true) {
        self.is24Hour = is24Hour
        self.showSeconds = showSeconds
        self.showDate = showDate
        self.showWeekday = showWeekday
        self.dateFormat = dateFormat
        self.customSeparator = customSeparator
        self.useLocalizedFormat = useLocalizedFormat
    }
}

/// 时钟核心类，负责时间逻辑、格式化和多时区处理
@MainActor
class ClockCore: ObservableObject {
    // MARK: - Published Properties
    @Published var currentTime: Date = Date()
    @Published var formattedTime: String = ""
    @Published var timeFormat: TimeFormat = TimeFormat()
    
    // MARK: - Private Properties
    private var timer: Timer?
    private let dateFormatter = DateFormatter()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupDateFormatter()
        startTimer()
        
        // 监听时间格式变化
        $timeFormat
            .sink { [weak self] _ in
                self?.setupDateFormatter()
                self?.updateFormattedTime()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Public Methods
    
    /// 更新时间格式
    func updateTimeFormat(_ format: TimeFormat) {
        timeFormat = format
        setupTimerFrequency()
    }
    
    /// 手动更新时间
    func updateTime() {
        currentTime = Date()
        updateFormattedTime()
    }
    
    // MARK: - Private Methods
    
    private func setupDateFormatter() {
        dateFormatter.locale = Locale.current
        
        var formatString = ""
        
        // 时间部分
        if timeFormat.is24Hour {
            formatString += timeFormat.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatString += timeFormat.showSeconds ? "h:mm:ss a" : "h:mm a"
        }
        
        // 日期部分
        if timeFormat.showDate {
            formatString = "yyyy-MM-dd " + formatString
        }
        
        // 星期部分
        if timeFormat.showWeekday {
            formatString = "EEE " + formatString
        }
        
        dateFormatter.dateFormat = formatString
    }
    
    private func startTimer() {
        setupTimerFrequency()
    }
    
    private func setupTimerFrequency() {
        stopTimer()
        
        // 根据是否显示秒来决定更新频率
        let interval: TimeInterval = timeFormat.showSeconds ? 1.0 : 60.0
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTime()
            }
        }
        
        // 立即更新一次
        updateTime()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateFormattedTime() {
        formattedTime = dateFormatter.string(from: currentTime)
    }
}