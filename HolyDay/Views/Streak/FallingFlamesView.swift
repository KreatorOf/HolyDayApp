//
//  FallingFlamesView.swift
//  HolyDay
//

import SwiftUI

// Static config computed once — random values are fixed at first access.
private struct FlameConfig: Identifiable {
  let id: Int
  let xFraction: CGFloat  // relative to screen width (0...1)
  let size: CGFloat
  let duration: Double
  let delay: Double
  let opacity: Double
}

private let flameConfigs: [FlameConfig] = (0..<22).map { i in
  FlameConfig(
    id: i,
    xFraction: CGFloat.random(in: 0.04...0.96),
    size: CGFloat.random(in: 14...38),
    duration: Double.random(in: 2.5...5.5),
    delay: Double.random(in: 0...3.0),
    opacity: Double.random(in: 0.5...0.85)
  )
}

struct FallingFlamesView: View {
  @State private var falling = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geo in
      ForEach(flameConfigs) { config in
        Text("🔥")
          .font(.system(size: config.size))
          .opacity(config.opacity)
          .position(
            x: geo.size.width * config.xFraction,
            y: falling ? geo.size.height + 60 : -60
          )
          .animation(
            .linear(duration: config.duration)
              .delay(config.delay)
              .repeatForever(autoreverses: false),
            value: falling
          )
      }
    }
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion else { return }
      falling = true
    }
  }
}
