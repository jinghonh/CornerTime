//
//  ContentView.swift
//  CornerTime
//
//  Created by JingHong on 2025/8/12.
//

import SwiftUI

/// 主内容视图（隐藏的主窗口内容）
struct ContentView: View {
    var body: some View {
        VStack {
            Text("CornerTime 正在运行")
                .font(.headline)
            Text("时钟显示在屏幕角落")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200, height: 100)
    }
}

#Preview {
    ContentView()
}
