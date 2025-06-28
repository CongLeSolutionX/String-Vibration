//
//MIT License
//
//Copyright © 2025 Cong Le
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  StringVibrationView.swift
//  MyApp
//
//  Created by Cong Le on 6/28/25.
//

import SwiftUI

// MARK: - Core Physics Logic & State Management (ViewModel)

/// Manages the state and physics calculations for the vibrating string simulation.
///
/// This an `ObservableObject`, allowing the SwiftUI view to reactively update whenever
/// its properties change. It encapsulates all the physics logic, keeping the View layer
/// clean and focused on presentation.
@MainActor
final class StringPhysicsViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI Controls)
    @Published var tension: Double = 25.0
    @Published var linearMassDensity: Double = 0.5
    @Published var harmonicMode: Int = 1
    @Published private(set) var animationPhase: Double = 0.0
    
    // MARK: - Constants
    let length: Double = 300.0
    
    // MARK: - Private Properties
    private var animationTimer: Timer?
    
    // MARK: - Computed Properties (Physics Output)
    var frequency: Double {
        guard linearMassDensity > 0 else { return 0 }
        let term1 = Double(harmonicMode) / (2 * length)
        let term2 = sqrt(tension / linearMassDensity)
        return term1 * term2 * 1000
    }
    
    // MARK: - Initializer & Animation Control
    init() {
        startAnimation()
    }
    
    /// Starts a timer to drive the string's vibration animation.
    private func startAnimation() {
        animationTimer?.invalidate()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            
            // ✅ CORRECT FIX: Use DispatchQueue to schedule the UI update on the main thread.
            // This is the standard way to update the main thread from a classic Timer closure.
            DispatchQueue.main.async {
                // Safely update the animation phase on the main thread.
                self?.animationPhase += 0.1
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}

// MARK: - Custom Shape for Drawing the String

/// A custom SwiftUI `Shape` that draws a vibrating string as a sine wave.
struct VibratingStringShape: Shape {
    let harmonicMode: Int
    let animationPhase: Double
    var amplitude: Double = 40.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width
        let timeAmplitude = sin(animationPhase) * amplitude
        
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, to: width, by: 2) {
            let standingWaveComponent = sin(CGFloat.pi * CGFloat(harmonicMode) * x / width)
            let y = midY - (timeAmplitude * standingWaveComponent)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: midY))
        return path
    }
}

// MARK: - Main SwiftUI View

/// A view that simulates a vibrating string to demonstrate the principles of SHM in music.
struct StringVibrationView: View {
    @StateObject private var viewModel = StringPhysicsViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // --- 🎵 Display Section ---
            Text("Vibrating String Simulation")
                .font(.largeTitle).fontWeight(.bold)
            Text("An Application of Simple Harmonic Motion")
                .font(.subheadline).foregroundStyle(.secondary)
            
            // --- 🎸 String Visualization ---
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 100))
                    path.addLine(to: CGPoint(x: viewModel.length, y: 100))
                }.stroke(Color.gray.opacity(0.5), lineWidth: 2)
                
                VibratingStringShape(
                    harmonicMode: viewModel.harmonicMode,
                    animationPhase: viewModel.animationPhase
                ).stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(width: viewModel.length, height: 200)
            .padding(.vertical)
            
            // --- 🔊 Output Section ---
            VStack {
                Text("Calculated Frequency").font(.headline)
                Text(String(format: "%.2f Hz", viewModel.frequency))
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: viewModel.frequency)
            }
            
            // --- ⚙️ Controls Section ---
            Form {
                VStack(alignment: .leading) {
                    Text("Tension (T): \(Int(viewModel.tension))")
                    Slider(value: $viewModel.tension, in: 1...100, step: 1)
                }
                
                VStack(alignment: .leading) {
                    Text("Linear Mass Density (μ): \(String(format: "%.2f", viewModel.linearMassDensity))")
                    Slider(value: $viewModel.linearMassDensity, in: 0.1...2.0, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("Harmonic Mode (n): \(viewModel.harmonicMode)")
                    Slider(value: Binding(
                        get: { Double(viewModel.harmonicMode) },
                        set: { viewModel.harmonicMode = Int($0) }
                    ), in: 1...8, step: 1)
                }
            }
            .frame(maxHeight: 280)
        }
        .padding()
    }
}

// MARK: - SwiftUI Preview
#Preview {
    StringVibrationView()
}
