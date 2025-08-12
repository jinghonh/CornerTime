//
//  ClockView.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 时钟显示视图
struct ClockView: View {
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // 锁定状态指示器 - 放在时钟上方避免重叠
            if viewModel.isLocked || viewModel.allowsClickThrough {
                LockIndicator(
                    isLocked: viewModel.isLocked,
                    allowsClickThrough: viewModel.allowsClickThrough
                )
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            
            // 主时钟显示
            HStack(spacing: 0) {
                Text(viewModel.currentTime)
                    .font(clockFont)
                    .foregroundColor(clockColor)
                    .opacity(clockOpacity)
                    .padding(clockPadding)
            }
            .background(clockBackground)
            .cornerRadius(clockCornerRadius)
            .shadow(
                color: viewModel.preferencesManager.appearanceConfig.enableShadow ? .black.opacity(0.1) : .clear,
                radius: viewModel.preferencesManager.appearanceConfig.shadowRadius,
                x: 0,
                y: 1
            )
            .onTapGesture {
                if !viewModel.allowsClickThrough {
                    handleClockTap()
                }
            }
            .contextMenu {
                ContextMenuBuilder(viewModel: viewModel).buildMainContextMenu()
            }
        }
        .animation(.easeInOut(duration: AppConstants.Animation.standardDuration), value: viewModel.isLocked)
        .animation(.easeInOut(duration: AppConstants.Animation.standardDuration), value: viewModel.allowsClickThrough)
    }
    
    // MARK: - Computed Properties
    
    private var clockFont: Font {
        let config = viewModel.preferencesManager.appearanceConfig
        
        let design: Font.Design = {
            switch config.fontDesign {
            case .default: return .default
            case .monospaced: return .monospaced
            case .rounded: return .rounded
            case .serif: return .serif
            }
        }()
        
        let weight: Font.Weight = {
            switch config.fontWeight {
            case .ultraLight: return .ultraLight
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            }
        }()
        
        return .system(size: config.fontSize, weight: weight, design: design)
    }
    
    private var clockColor: Color {
        // 根据系统外观自动调整颜色
        Color.primary
    }
    
    private var clockOpacity: Double {
        viewModel.preferencesManager.appearanceConfig.opacity
    }
    
    private var clockPadding: EdgeInsets {
        EdgeInsets(
            top: AppConstants.UI.clockPaddingTop, 
            leading: AppConstants.UI.clockPaddingLeading, 
            bottom: AppConstants.UI.clockPaddingBottom, 
            trailing: AppConstants.UI.clockPaddingTrailing
        )
    }
    
    private var clockBackground: some View {
        Group {
            if viewModel.preferencesManager.appearanceConfig.useBlurBackground {
                // 毛玻璃背景
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            } else {
                // 透明背景
                Color.clear
            }
        }
    }
    
    private var clockCornerRadius: CGFloat {
        viewModel.preferencesManager.appearanceConfig.cornerRadius
    }
    
    
    // MARK: - Private Methods
    
    private func handleClockTap() {
        // 非穿透模式下的点击处理
        // 可以在这里添加其他交互功能
        print("时钟被点击")
    }
}

/// 毛玻璃效果视图
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    init(material: NSVisualEffectView.Material = .hudWindow,
         blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

#Preview {
    ClockView(viewModel: ClockViewModel())
        .frame(width: 200, height: 60)
}