//
//  SparksView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 23/05/2026.
//

import Combine
import SwiftUI

struct Spark: Identifiable {
  let id = UUID()
  var xPos: CGFloat
  var yPos: CGFloat
  var size: CGFloat
  var speed: CGFloat
  var opacity: Double
  var drift: CGFloat
}

struct SparksView: View {
  @State private var sparks: [Spark] = []
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geo in
      ZStack {
        ForEach(sparks) { spark in
          Circle()
            .fill(.white.opacity(spark.opacity))
            .frame(width: spark.size, height: spark.size)
            .position(x: spark.xPos, y: spark.yPos)
            .blur(radius: 1.2)
        }
      }
      .accessibilityHidden(true)
      .onAppear {
        guard !reduceMotion else { return }
        for _ in 0..<18 {
          spawn(in: geo.size)
        }
      }
      .onReceive(timer) { _ in
        guard !reduceMotion else { return }
        update(in: geo.size)
      }
    }
  }

  private func spawn(in size: CGSize) {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)

    sparks.append(
      Spark(
        xPos: center.x + CGFloat.random(in: -40...40),
        yPos: center.y + CGFloat.random(in: -40...40),
        size: CGFloat.random(in: 2...5),
        speed: CGFloat.random(in: 0.8...2.0),
        opacity: Double.random(in: 0.2...0.8),
        drift: CGFloat.random(in: -0.6...0.6)
      )
    )
  }

  private func update(in size: CGSize) {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)

    for i in sparks.indices {
      sparks[i].yPos -= sparks[i].speed
      sparks[i].xPos += sparks[i].drift
      sparks[i].opacity -= 0.004

      if sparks[i].opacity <= 0 {
        sparks[i] = Spark(
          xPos: center.x + CGFloat.random(in: -40...40),
          yPos: center.y + CGFloat.random(in: -40...40),
          size: CGFloat.random(in: 2...5),
          speed: CGFloat.random(in: 0.8...2.0),
          opacity: Double.random(in: 0.2...0.8),
          drift: CGFloat.random(in: -0.6...0.6)
        )
      }
    }
  }
}
