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
    let side: CGFloat = 256
    let size = CGSize(width: side, height: side)
    let renderer = UIGraphicsImageRenderer(size: size)
    let squared = renderer.image { _ in
      // Aspect-fill : mise à l'échelle qui couvre le carré sans déformer (le plus petit côté
      // remplit), centrée ; le débordement est rogné par les bornes du renderer. Évite
      // l'étirement obtenu en dessinant directement dans un CGRect carré.
      let scale = max(side / image.size.width, side / image.size.height)
      let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
      let origin = CGPoint(x: (side - scaled.width) / 2, y: (side - scaled.height) / 2)
      image.draw(in: CGRect(origin: origin, size: scaled))
    }
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
