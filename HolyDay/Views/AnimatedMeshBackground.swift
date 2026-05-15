//
//  AnimatedMeshBackground.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct AnimatedMeshBackground: View {
    @State private var animate = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0),
                .init(0.0, 0.5), .init(animate ? 0.65 : 0.35, animate ? 0.45 : 0.55), .init(1.0, 0.5),
                .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)
            ],
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.07, green: 0.05, blue: 0.16),
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.08, green: 0.06, blue: 0.18),
                animate ? Color(red: 0.22, green: 0.10, blue: 0.38) : Color(red: 0.12, green: 0.06, blue: 0.26),
                Color(red: 0.04, green: 0.07, blue: 0.16),
                Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.06, green: 0.04, blue: 0.14),
                Color(red: 0.05, green: 0.05, blue: 0.12)
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
