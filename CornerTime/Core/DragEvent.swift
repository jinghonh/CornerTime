//
//  DragEvent.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import Foundation

/// 拖拽事件类型
enum DragEvent {
    case started(CGPoint)
    case moved(CGPoint)
    case ended
}