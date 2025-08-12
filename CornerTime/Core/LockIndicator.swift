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
    @State private var hideTask: Task<Void, Never>?
    
    // 常量
    private let autoHideDelay: TimeInterval = 3.0
    private let animationDuration: TimeInterval = 0.3
    
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
        .animation(.easeInOut(duration: animationDuration), value: isVisible)
        .onAppear {
            scheduleAutoHide()
        }
        .onChange(of: isLocked) { _ in
            handleStateChange()
        }
        .onChange(of: allowsClickThrough) { _ in
            handleStateChange()
        }
        .onDisappear {
            hideTask?.cancel()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleStateChange() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isVisible = true
        }
        scheduleAutoHide()
    }
    
    private func scheduleAutoHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(autoHideDelay))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: animationDuration)) {
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