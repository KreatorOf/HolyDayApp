//
//  AnimatedMeshBackground.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct AnimatedMeshBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0),
                .init(0.0, 0.5), .init(animate ? 0.65 : 0.35, animate ? 0.45 : 0.55), .init(1.0, 0.5),
                .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)
            ],
            colors: colorScheme == .dark ? darkColors : lightColors
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    // Dark: deep navy-violet, centre violet animé
    private var darkColors: [Color] {[
        Color(red: 0.05, green: 0.05, blue: 0.12),
        Color(red: 0.07, green: 0.05, blue: 0.16),
        Color(red: 0.05, green: 0.05, blue: 0.12),
        Color(red: 0.08, green: 0.06, blue: 0.18),
        animate ? Color(red: 0.22, green: 0.10, blue: 0.38) : Color(red: 0.12, green: 0.06, blue: 0.26),
        Color(red: 0.04, green: 0.07, blue: 0.16),
        Color(red: 0.05, green: 0.05, blue: 0.12),
        Color(red: 0.06, green: 0.04, blue: 0.14),
        Color(red: 0.05, green: 0.05, blue: 0.12)
    ]}

    // Light "Aube": crème chaud #F8F3EC, centre doré qui respire
    private var lightColors: [Color] {[
        Color(red: 0.973, green: 0.953, blue: 0.925),
        Color(red: 0.961, green: 0.937, blue: 0.902),
        Color(red: 0.973, green: 0.953, blue: 0.925),
        Color(red: 0.965, green: 0.945, blue: 0.914),
        animate ? Color(red: 0.918, green: 0.878, blue: 0.820) : Color(red: 0.941, green: 0.910, blue: 0.863),
        Color(red: 0.969, green: 0.953, blue: 0.929),
        Color(red: 0.973, green: 0.953, blue: 0.925),
        Color(red: 0.965, green: 0.945, blue: 0.910),
        Color(red: 0.973, green: 0.953, blue: 0.925)
    ]}
}
