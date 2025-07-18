//
//  ContentView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

func longRunningTask(
    totalSteps: Int,
    progress: Binding<Double>,
    isProcessing: Binding<Bool>
) async {
    // 确保在任务开始前重置状态
    await MainActor.run {
        progress.wrappedValue = 0.0
        isProcessing.wrappedValue = true
    }
    
    for step in 0..<totalSteps {
        // 检查任务是否被取消
        if Task.isCancelled { break }
        
        // 执行实际工作（替换为你的业务逻辑）
        await processWorkStep(step)
        
        // 更新进度（主线程安全）
        await updateProgress(
            progress: progress,
            currentStep: step + 1,
            totalSteps: totalSteps
        )
    }
    
    // 任务完成后更新状态
    await MainActor.run {
        isProcessing.wrappedValue = false
    }
}

// 工作步骤处理（可自定义）
private func processWorkStep(_ step: Int) async {
    // 模拟耗时操作
    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    
    // 实际业务逻辑示例：
    // let data = loadData(for: step)
    // let result = complexCalculation(data)
    // saveResult(result)
}

// 安全更新进度（处理主线程）
private func updateProgress(
    progress: Binding<Double>,
    currentStep: Int,
    totalSteps: Int
) async {
    await MainActor.run {
        progress.wrappedValue = Double(currentStep) / Double(totalSteps)
    }
}

struct ContentttView: View {
    @State private var progress: Double = 0.0
    @State private var isProcessing = false
    @State private var currentTask: Task<Void, Never>?
    private let totalSteps = 100
    
    var body: some View {
        VStack(spacing: 20) {

            Button("Start Processing") {
                startTask()
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $isProcessing) {
                ProgressView("Processing...", value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .padding()
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .animation(.easeInOut, value: progress)
                
                Button("Cancel") {
                    currentTask?.cancel()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        
        .padding()
        .animation(.easeInOut, value: isProcessing)
    }
    
    private func startTask() {
        currentTask = Task {
            await longRunningTask(
                totalSteps: totalSteps,
                progress: $progress,
                isProcessing: $isProcessing
            )
        }
    }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack {
            Button("Kemono content") {
                openWindow(id: "viewer")
            }
            Button("Twitter content") {
                openWindow(id: "twitterViewer")
            }
            Button("Kemono Renamer") {
                openWindow(id: "renamer")
            }
        }
        .padding()
    }
    
}

#Preview {
//    ContentView()
    ContentttView()
}
