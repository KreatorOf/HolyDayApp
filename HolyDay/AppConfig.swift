//
//  AppConfig.swift
//  HolyDay
//
//  Created by Matthias Cadet on 15/05/2026.
//
//  Lit les valeurs injectées par les xcconfig via Info.plist.
//  Ne jamais mettre de valeurs en dur ici.

import Foundation

enum AppConfig {

  // MARK: - Supabase

  static let supabaseURL: String = {
    guard let v = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String, !v.isEmpty
    else {
      assertionFailure(
        "SupabaseURL manquant — vérifie que Secrets.<env>.xcconfig est créé et assigné")
      return ""
    }
    return v
  }()

  static let supabaseAnonKey: String = {
    guard let v = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String, !v.isEmpty
    else {
      assertionFailure(
        "SupabaseAnonKey manquant — vérifie que Secrets.<env>.xcconfig est créé et assigné")
      return ""
    }
    return v
  }()

}
