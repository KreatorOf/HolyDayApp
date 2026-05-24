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
        guard let v = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String, !v.isEmpty else {
            assertionFailure("SupabaseURL manquant — vérifie que Secrets.<env>.xcconfig est créé et assigné")
            return ""
        }
        return v
    }()

    static let supabaseAnonKey: String = {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String, !v.isEmpty else {
            assertionFailure("SupabaseAnonKey manquant — vérifie que Secrets.<env>.xcconfig est créé et assigné")
            return ""
        }
        return v
    }()

    // MARK: - Environment

    enum Environment: String {
        case debug   = "Debug"
        case staging = "Staging"
        case release = "Release"
    }

    static let environment: Environment = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String ?? "Release"
        return Environment(rawValue: raw) ?? .release
    }()

    static var isDebug: Bool { environment == .debug }
    static var isStaging: Bool { environment == .staging }
    static var isRelease: Bool { environment == .release }

    // MARK: - Logging

    static let isLoggingEnabled: Bool = {
        let v = Bundle.main.object(forInfoDictionaryKey: "LoggingEnabled") as? String ?? "NO"
        return v == "YES"
    }()

    static func log(_ message: String, file: String = #fileID, line: Int = #line) {
        guard isLoggingEnabled else { return }
        print("[\(environment.rawValue)] \(file):\(line) → \(message)")
    }
}
