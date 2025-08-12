//
//  LockIndicator.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 锁定状态指示器
struct LockIndicator: View {
    let isLocked: Bool
    let allowsClickThrough: Bool
    @State private var isVisible = true
    
    var body: some View {
        HStack(spacing: 4) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                    .help("位置已锁定")
            }
            
            if allowsClickThrough {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundColor(.blue)
                    .help("点击穿透已启用")
            }
        }
        .font(.caption)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Color.black.opacity(0.1)
                .blur(radius: 2)
        )
        .cornerRadius(4)
        .opacity(isVisible ? 0.8 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            // 显示指示器3秒后自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isVisible = false
                }
            }
        }
        .onChange(of: isLocked) { _ in
            // 状态变化时重新显示
            withAnimation {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isVisible = false
                }
            }
        }
        .onChange(of: allowsClickThrough) { _ in
            // 状态变化时重新显示
            withAnimation {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LockIndicator(isLocked: true, allowsClickThrough: false)
        LockIndicator(isLocked: false, allowsClickThrough: true)
        LockIndicator(isLocked: true, allowsClickThrough: true)
        LockIndicator(isLocked: false, allowsClickThrough: false)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}