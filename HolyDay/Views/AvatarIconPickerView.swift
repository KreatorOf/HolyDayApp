//
//  AvatarIconPickerView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 24/05/2026.
//

import SwiftUI
import UIKit

// MARK: - Icon catalogue

struct AvatarIconOption: Identifiable {
    let id: String
    let symbol: String
    let color: Color
}

extension AvatarIconOption {
    static let all: [AvatarIconOption] = [
        AvatarIconOption(id: "dove",     symbol: "dove.fill",           color: AppTheme.adorationPurple),
        AvatarIconOption(id: "cross",    symbol: "cross.fill",          color: AppTheme.confessionBlue),
        AvatarIconOption(id: "heart",    symbol: "heart.fill",          color: .pink),
        AvatarIconOption(id: "star",     symbol: "star.fill",           color: AppTheme.thanksgivingGold),
        AvatarIconOption(id: "leaf",     symbol: "leaf.fill",           color: AppTheme.supplicationGreen),
        AvatarIconOption(id: "flame",    symbol: "flame.fill",          color: .orange),
        AvatarIconOption(id: "sparkles", symbol: "sparkles",            color: AppTheme.adorationPurple),
        AvatarIconOption(id: "moon",     symbol: "moon.stars.fill",     color: .indigo),
        AvatarIconOption(id: "sun",      symbol: "sun.max.fill",        color: AppTheme.thanksgivingGold),
        AvatarIconOption(id: "drop",     symbol: "drop.fill",           color: AppTheme.confessionBlue),
        AvatarIconOption(id: "hands",    symbol: "hands.sparkles.fill", color: AppTheme.adorationPurple),
        AvatarIconOption(id: "book",     symbol: "book.fill",           color: AppTheme.confessionBlue),
        AvatarIconOption(id: "music",    symbol: "music.note",          color: .pink),
        AvatarIconOption(id: "globe",    symbol: "globe",               color: AppTheme.supplicationGreen),
        AvatarIconOption(id: "person",   symbol: "person.fill",         color: AppTheme.textSecondary),
        AvatarIconOption(id: "mountain", symbol: "mountain.2.fill",     color: AppTheme.supplicationGreen),
    ]

    static func find(id: String) -> AvatarIconOption? {
        all.first { $0.id == id }
    }
}

// MARK: - Icon picker sheet

struct AvatarIconPickerView: View {
    @Binding var selectedId: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AvatarIconOption.all) { option in
                        iconCell(option)
                            .onTapGesture { pick(option) }
                    }
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .background { AnimatedMeshBackground() }
            .navigationTitle("settings.avatar.picker.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func iconCell(_ option: AvatarIconOption) -> some View {
        let isSelected = selectedId == option.id
        return ZStack(alignment: .topTrailing) {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .strokeBorder(
                            isSelected ? option.color : AppTheme.cardStroke,
                            lineWidth: isSelected ? 2 : 1
                        )
                }

            Image(systemName: option.symbol)
                .font(.system(size: 26, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(option.color)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(option.color)
                    .background(Circle().fill(AppTheme.backgroundPrimary))
                    .offset(x: 4, y: -4)
            }
        }
        .frame(width: 72, height: 72)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func pick(_ option: AvatarIconOption) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedId = option.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
    }
}

// MARK: - UIKit camera wrapper

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
