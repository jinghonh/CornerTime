//
//  CornerTimeApp.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI
import AppKit

@main
struct CornerTimeApp: App {
    @StateObject private var clockViewModel = ClockViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 主时钟窗口 - 设置为不可见，因为我们使用自定义窗口
        WindowGroup {
            ContentView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    init() {
        // 设置应用启动时的初始配置
        setupApplication()
    }
    
    private func setupApplication() {
        // 确保应用在启动时不显示在 Dock 中
        NSApp.setActivationPolicy(.accessory)
    }
}

/// 应用委托，处理应用生命周期事件
class AppDelegate: NSObject, NSApplicationDelegate {
    var clockViewModel: ClockViewModel?
    var clockWindowController: ClockWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化时钟视图模型
        clockViewModel = ClockViewModel()
        
        // 创建并显示时钟窗口
        setupClockWindow()
        
        // 隐藏主窗口
        hideMainWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 应用即将退出时的清理工作
        clockWindowController?.cleanup()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当用户点击 Dock 图标时的处理（如果显示在 Dock 中）
        clockViewModel?.toggleVisibility()
        return false
    }
    
    private func setupClockWindow() {
        guard let viewModel = clockViewModel else { return }
        
        clockWindowController = ClockWindowController(viewModel: viewModel)
        clockWindowController?.showWindow()
    }
    
    private func hideMainWindow() {
        // 隐藏默认的主窗口
        for window in NSApp.windows {
            if window.title.isEmpty || window.title == "CornerTime" {
                window.orderOut(nil)
            }
        }
    }
}
