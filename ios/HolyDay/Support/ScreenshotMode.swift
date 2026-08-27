//
//  ScreenshotMode.swift
//  HolyDay
//

import Foundation

/// Rend le lancement déterministe pendant les runs de capture d'écran (`fastlane snapshot`) :
/// pas de splash, pas d'onboarding, pas de tips, émotion pré-sélectionnée. Neutre en Release
/// (`isActive` renvoie toujours `false`), donc aucune branche de capture n'est atteinte en prod.
enum ScreenshotMode {
  static var isActive: Bool {
    #if DEBUG
      return ProcessInfo.processInfo.arguments.contains("--uiTestScreenshots")
    #else
      return false
    #endif
  }

  /// Émotion à pré-sélectionner sur l'écran d'accueil, passée via `--screenshotEmotion <rawValue>`.
  static var preselectedEmotion: Emotion? {
    #if DEBUG
      let args = ProcessInfo.processInfo.arguments
      guard let index = args.firstIndex(of: "--screenshotEmotion"), index + 1 < args.count else {
        return nil
      }
      return Emotion(rawValue: args[index + 1])
    #else
      return nil
    #endif
  }
}
