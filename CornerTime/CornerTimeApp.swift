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
        // 主窗口 - 保持最小化但可见，确保程序坞图标显示
        WindowGroup {
            ContentView()
                .frame(width: 200, height: 100)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
    }
    
    init() {
        // 其他初始化设置可以在这里进行
        // NSApp 相关的设置需要在 AppDelegate 中进行
    }
}

/// 应用委托，处理应用生命周期事件
class AppDelegate: NSObject, NSApplicationDelegate {
    var clockViewModel: ClockViewModel?
    var clockWindowController: ClockWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 CornerTime 应用启动中...")
        
        // 设置应用在 Dock 中显示
        // 注意：.regular 会显示程序坞图标，.accessory 不会显示
        NSApp.setActivationPolicy(.regular)
        print("✅ 应用策略设置为 regular 模式，将在程序坞显示图标")
        
        // 激活应用程序以确保图标显示
        NSApp.activate(ignoringOtherApps: true)
        
        // 初始化时钟视图模型
        clockViewModel = ClockViewModel()
        print("✅ 时钟视图模型初始化完成")
        
        // 创建并显示时钟窗口
        Task { @MainActor in
            setupClockWindow()
        }
        
        // 最小化主窗口但保持可见性（确保程序坞图标显示）
        minimizeMainWindow()
        
        print("🎯 CornerTime 启动完成！时钟应该显示在屏幕右上角")
        print("💡 提示：使用 Cmd+Ctrl+Space 切换显示/隐藏")
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
    
    @MainActor
    private func setupClockWindow() {
        guard let viewModel = clockViewModel else { 
            print("❌ 错误：时钟视图模型为空")
            return 
        }
        
        print("🔧 创建时钟窗口控制器...")
        clockWindowController = ClockWindowController(viewModel: viewModel)
        
        print("👁️ 显示时钟窗口...")
        clockWindowController?.showWindow()
    }
    
    private func minimizeMainWindow() {
        // 最小化主窗口但保持应用程序在程序坞的可见性
        for window in NSApp.windows {
            if window.title.isEmpty || window.title == "CornerTime" {
                window.miniaturize(nil)
                print("🏠 主窗口已最小化")
            }
        }
    }
}
