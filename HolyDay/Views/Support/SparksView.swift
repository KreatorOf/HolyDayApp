//
//  SparksView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 23/05/2026.
//

import SwiftUI

struct Spark {
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

  var body: some View {
    GeometryReader { geo in
      TimelineView(.periodic(from: .now, by: 1.0 / 20.0)) { timeline in
        Canvas { context, _ in
          for spark in sparks {
            var path = Path()
            path.addEllipse(
              in: CGRect(
                x: spark.xPos - spark.size / 2,
                y: spark.yPos - spark.size / 2,
                width: spark.size,
                height: spark.size
              ))
            context.fill(path, with: .color(.white.opacity(spark.opacity)))
          }
        }
        .onChange(of: timeline.date) { _, _ in
          guard !reduceMotion else { return }
          update(in: geo.size)
        }
      }
      .blur(radius: 1.5)
      .accessibilityHidden(true)
      .onAppear {
        guard !reduceMotion else { return }
        for _ in 0..<18 { spawn(in: geo.size) }
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
      ))
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
