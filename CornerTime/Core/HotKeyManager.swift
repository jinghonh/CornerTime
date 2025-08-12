//
//  HotKeyManager.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import AppKit
import Carbon
import Foundation

/// 快捷键配置
struct HotKeyConfig {
    let keyCode: UInt32
    let modifiers: UInt32
    let identifier: String
    
    init(keyCode: UInt32, modifiers: UInt32, identifier: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.identifier = identifier
    }
    
    /// 默认快捷键配置
    static let defaultToggleVisibility = HotKeyConfig(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(cmdKey | controlKey),
        identifier: "toggleVisibility"
    )
    
    static let defaultToggleLock = HotKeyConfig(
        keyCode: UInt32(kVK_ANSI_L),
        modifiers: UInt32(cmdKey | controlKey),
        identifier: "toggleLock"
    )
    
    static let defaultToggleClickThrough = HotKeyConfig(
        keyCode: UInt32(kVK_ANSI_T),
        modifiers: UInt32(cmdKey | controlKey),
        identifier: "toggleClickThrough"
    )
}

/// 快捷键动作类型
enum HotKeyAction {
    case toggleVisibility
    case toggleLock
    case toggleClickThrough
    case showSettings
    case quit
}

/// 全局快捷键管理器
class HotKeyManager: ObservableObject {
    // MARK: - Properties
    private var registeredHotKeys: [String: EventHotKeyRef] = [:]
    private var hotKeyActions: [String: () -> Void] = [:]
    private var eventHandler: EventHandlerRef?
    
    // MARK: - Initialization
    init() {
        setupEventHandler()
    }
    
    deinit {
        unregisterAllHotKeys()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
    
    // MARK: - Public Methods
    
    /// 注册快捷键
    func registerHotKey(_ config: HotKeyConfig, action: @escaping () -> Void) {
        // 先注销已存在的快捷键
        unregisterHotKey(identifier: config.identifier)
        
        var hotKeyRef: EventHotKeyRef?
        // 安全地转换哈希值，避免整数溢出
        let hashValue = abs(config.identifier.hash)
        let signature = OSType(hashValue & 0xFFFFFFFF)  // 截取低32位
        let hotKeyID = EventHotKeyID(signature: signature, id: UInt32(hashValue & 0xFFFFFFFF))
        
        let status = RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let keyRef = hotKeyRef {
            registeredHotKeys[config.identifier] = keyRef
            hotKeyActions[config.identifier] = action
            print("成功注册快捷键: \(config.identifier)")
        } else {
            print("注册快捷键失败: \(config.identifier), 状态码: \(status)")
        }
    }
    
    /// 注销快捷键
    func unregisterHotKey(identifier: String) {
        if let hotKeyRef = registeredHotKeys[identifier] {
            UnregisterEventHotKey(hotKeyRef)
            registeredHotKeys.removeValue(forKey: identifier)
            hotKeyActions.removeValue(forKey: identifier)
            print("注销快捷键: \(identifier)")
        }
    }
    
    /// 注销所有快捷键
    func unregisterAllHotKeys() {
        for identifier in registeredHotKeys.keys {
            unregisterHotKey(identifier: identifier)
        }
    }
    
    /// 注册默认快捷键
    func registerDefaultHotKeys(
        onToggleVisibility: @escaping () -> Void,
        onToggleLock: @escaping () -> Void,
        onToggleClickThrough: @escaping () -> Void
    ) {
        registerHotKey(.defaultToggleVisibility, action: onToggleVisibility)
        registerHotKey(.defaultToggleLock, action: onToggleLock)
        registerHotKey(.defaultToggleClickThrough, action: onToggleClickThrough)
    }
    
    // MARK: - Private Methods
    
    private func setupEventHandler() {
        let eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]
        
        let callback: EventHandlerProcPtr = { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
            manager.handleHotKeyPress(hotKeyID: hotKeyID)
            
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            eventTypes,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
    }
    
    private func handleHotKeyPress(hotKeyID: EventHotKeyID) {
        // 根据热键ID查找对应的动作
        for (identifier, action) in hotKeyActions {
            let expectedSignature = OSType(identifier.hash)
            let expectedID = UInt32(identifier.hash)
            
            if hotKeyID.signature == expectedSignature && hotKeyID.id == expectedID {
                DispatchQueue.main.async {
                    action()
                }
                break
            }
        }
    }
}