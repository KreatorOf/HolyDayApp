//
//  AvatarService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 24/05/2026.
//

import UIKit

final class AvatarService {
  static let shared = AvatarService()

  private init() {}

  private var avatarURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("holyday_avatar.jpg")
  }

  func save(_ image: UIImage) {
    let size = CGSize(width: 256, height: 256)
    let renderer = UIGraphicsImageRenderer(size: size)
    let squared = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    if let data = squared.jpegData(compressionQuality: 0.85) {
      try? data.write(to: avatarURL, options: .atomic)
    }
  }

  func load() -> UIImage? {
    guard let data = try? Data(contentsOf: avatarURL) else { return nil }
    return UIImage(data: data)
  }

  func delete() {
    try? FileManager.default.removeItem(at: avatarURL)
  }
}
