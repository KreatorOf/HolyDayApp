//
//  FeatureVoteService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import Observation

// MARK: - Configuration
// Les valeurs sont lues depuis AppConfig, injectées via les xcconfig (Config/Secrets.<env>.xcconfig).
private enum SupabaseConfig {
  static var url: String { AppConfig.supabaseURL }
  static var anonKey: String { AppConfig.supabaseAnonKey }
}

// MARK: - Service

@MainActor
@Observable
final class FeatureVoteService {
  var proposals: [FeatureProposal] = []
  var isLoading = false
  var error: String?

  private var deviceID: String {
    let key = "holyday.deviceID"
    if let stored = UserDefaults.standard.string(forKey: key) { return stored }
    let new = UUID().uuidString
    UserDefaults.standard.set(new, forKey: key)
    return new
  }

  private var isConfigured: Bool {
    !SupabaseConfig.url.isEmpty && !SupabaseConfig.anonKey.isEmpty
  }

  func load() async {
    guard isConfigured else {
      error = "Supabase non configuré — remplis SupabaseConfig dans FeatureVoteService.swift"
      return
    }

    isLoading = true
    error = nil

    do {
      async let features = fetchFeatures()
      async let userVotes = fetchUserVotes()
      let (loadedFeatures, votedIDs) = try await (features, userVotes)

      proposals = loadedFeatures.map { f in
        FeatureProposal(
          id: f.id,
          title: f.title,
          description: f.description,
          icon: f.icon,
          voteCount: f.voteCount,
          hasVoted: votedIDs.contains(f.id)
        )
      }
    } catch {
      self.error = "Impossible de charger les fonctionnalités."
    }

    isLoading = false
  }

  func vote(for proposal: FeatureProposal) async {
    guard isConfigured,
      !proposal.hasVoted,
      let idx = proposals.firstIndex(where: { $0.id == proposal.id })
    else { return }

    proposals[idx].hasVoted = true
    proposals[idx].voteCount += 1

    do {
      guard let url = URL(string: "\(SupabaseConfig.url)/rest/v1/votes") else {
        throw URLError(.badURL)
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("application/json", forHTTPHeaderField: "Accept")
      request.addValue("return=minimal", forHTTPHeaderField: "Prefer")
      request.httpBody = try JSONEncoder().encode([
        "feature_id": proposal.id,
        "device_id": deviceID,
      ])
      let (_, response) = try await URLSession.shared.data(for: request)
      guard (response as? HTTPURLResponse)?.statusCode == 201 else {
        throw URLError(.badServerResponse)
      }
    } catch {
      proposals[idx].hasVoted = false
      proposals[idx].voteCount -= 1
    }
  }

  // MARK: Private helpers

  private func fetchFeatures() async throws -> [SupabaseFeature] {
    guard
      var components = URLComponents(string: "\(SupabaseConfig.url)/rest/v1/features_with_votes")
    else {
      throw URLError(.badURL)
    }
    components.queryItems = [
      URLQueryItem(name: "select", value: "*"),
      URLQueryItem(name: "order", value: "vote_count.desc"),
    ]
    guard let url = components.url else { throw URLError(.badURL) }

    var request = URLRequest(url: url)
    request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([SupabaseFeature].self, from: data)
  }

  private func fetchUserVotes() async throws -> [String] {
    guard var components = URLComponents(string: "\(SupabaseConfig.url)/rest/v1/votes") else {
      throw URLError(.badURL)
    }
    components.queryItems = [
      URLQueryItem(name: "select", value: "feature_id"),
      URLQueryItem(name: "device_id", value: "eq.\(deviceID)"),
    ]
    guard let url = components.url else { throw URLError(.badURL) }

    var request = URLRequest(url: url)
    request.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([SupabaseVote].self, from: data).map(\.featureId)
  }
}

// MARK: - Supabase response models

private struct SupabaseFeature: Decodable {
  let id: String
  let title: String
  let description: String
  let icon: String
  let voteCount: Int

  enum CodingKeys: String, CodingKey {
    case id, title, description, icon
    case voteCount = "vote_count"
  }
}

private struct SupabaseVote: Decodable {
  let featureId: String
  enum CodingKeys: String, CodingKey { case featureId = "feature_id" }
}
