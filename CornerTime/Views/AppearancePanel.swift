//
//  AppearancePanel.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 外观设置面板
struct AppearancePanel: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var showPanel = false
    @State private var tempFontSize: CGFloat = 24
    @State private var tempOpacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("外观设置")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("完成") {
                    showPanel = false
                }
                .buttonStyle(.borderless)
            }
            .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 字体设置组
                    fontSettingsGroup
                    
                    Divider()
                    
                    // 时间格式组
                    timeFormatGroup
                    
                    Divider()
                    
                    // 外观效果组
                    appearanceEffectsGroup
                    
                    Divider()
                    
                    // 预览区域
                    previewSection
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 350, height: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var fontSettingsGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("字体设置")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // 字体大小滑块
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("字体大小")
                    Spacer()
                    Text("\(Int(tempFontSize))pt")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $tempFontSize, in: 12...48, step: 2) {
                    Text("字体大小")
                } minimumValueLabel: {
                    Text("12")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("48")
                        .font(.caption)
                } onEditingChanged: { _ in
                    viewModel.updateFontSize(tempFontSize)
                }
            }
            
            // 字体粗细选择
            VStack(alignment: .leading, spacing: 6) {
                Text("字体粗细")
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(FontWeightOption.allCases, id: \.self) { weight in
                        Button(weight.displayName) {
                            viewModel.updateFontWeight(weight)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .background(
                            weight == viewModel.preferencesManager.appearanceConfig.fontWeight ?
                            Color.accentColor.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
            }
            
            // 字体设计选择
            VStack(alignment: .leading, spacing: 6) {
                Text("字体设计")
                
                HStack(spacing: 8) {
                    ForEach(FontDesignOption.allCases, id: \.self) { design in
                        Button(design.displayName) {
                            viewModel.updateFontDesign(design)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .background(
                            design == viewModel.preferencesManager.appearanceConfig.fontDesign ?
                            Color.accentColor.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    private var timeFormatGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间格式")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // 12/24小时制
            HStack {
                Text("时间制式")
                Spacer()
                Button(viewModel.preferencesManager.timeFormat.is24Hour ? "24小时制" : "12小时制") {
                    viewModel.toggle24HourFormat()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // 显示秒
            HStack {
                Text("显示秒")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.preferencesManager.timeFormat.showSeconds },
                    set: { _ in viewModel.toggleSecondsDisplay() }
                ))
                .toggleStyle(.switch)
            }
            
            // 日期格式
            VStack(alignment: .leading, spacing: 6) {
                Text("日期格式")
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(DateFormatOption.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            viewModel.updateDateFormat(format)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .background(
                            format == viewModel.preferencesManager.timeFormat.dateFormat ?
                            Color.accentColor.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    private var appearanceEffectsGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("视觉效果")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // 透明度滑块
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("透明度")
                    Spacer()
                    Text("\(Int(tempOpacity * 100))%")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $tempOpacity, in: 0.3...1.0, step: 0.1) {
                    Text("透明度")
                } minimumValueLabel: {
                    Text("30%")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("100%")
                        .font(.caption)
                } onEditingChanged: { _ in
                    viewModel.updateOpacity(tempOpacity)
                }
            }
            
            // 阴影效果
            HStack {
                Text("阴影效果")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.preferencesManager.appearanceConfig.enableShadow },
                    set: { _ in viewModel.toggleShadow() }
                ))
                .toggleStyle(.switch)
            }
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预览")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Spacer()
                
                // 预览时钟
                Text(viewModel.currentTime)
                    .font(clockFont)
                    .foregroundColor(.primary)
                    .opacity(viewModel.preferencesManager.appearanceConfig.opacity)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .shadow(
                        color: viewModel.preferencesManager.appearanceConfig.enableShadow ? .black.opacity(0.1) : .clear,
                        radius: viewModel.preferencesManager.appearanceConfig.shadowRadius,
                        x: 0,
                        y: 1
                    )
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
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
    
    private func loadCurrentSettings() {
        tempFontSize = viewModel.preferencesManager.appearanceConfig.fontSize
        tempOpacity = viewModel.preferencesManager.appearanceConfig.opacity
    }
}

/// 外观设置按钮
struct AppearanceButton: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var showingPanel = false
    
    var body: some View {
        Button("外观设置...") {
            showingPanel = true
        }
        .popover(isPresented: $showingPanel) {
            AppearancePanel(viewModel: viewModel)
        }
    }
}

#Preview {
    AppearancePanel(viewModel: ClockViewModel())
        .padding()
}