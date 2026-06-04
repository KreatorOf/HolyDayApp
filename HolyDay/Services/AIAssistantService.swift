//
//  AIAssistantService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  // MARK: - Generable output types

  @Generable
  struct ReflectionQuestions {
    @Guide(
      description:
        "3 short open-ended questions in French to help the user reflect personally before writing their prayer for this specific step",
      .count(3)
    )
    var questions: [String]
  }

  @Generable
  struct SearchMatches {
    @Guide(
      description: """
        Les numéros des prières dont le sens correspond à la recherche de l'utilisateur, \
        même sans mots identiques. Liste vide si aucune ne correspond.
        """)
    var indices: [Int]
  }
#endif

// MARK: - Service

final class AIAssistantService {
  static let shared = AIAssistantService()

  private init() {}

  // MARK: Reflection questions

  func generateReflectionQuestions(for step: PrayerStep, recentEntries: [PrayerEntry] = [])
    async throws -> [String]
  {
    #if canImport(FoundationModels)
      let session = LanguageModelSession(instructions: reflectionSystemPrompt)
      let prompt = reflectionPrompt(for: step, recentEntries: recentEntries)
      let response = try await session.respond(to: prompt, generating: ReflectionQuestions.self)
      return response.content.questions
    #else
      // FoundationModels absent du SDK : l'aide à la réflexion est facultative, on dégrade
      // silencieusement vers aucune question.
      return []
    #endif
  }

  // MARK: Semantic search

  func searchEntries(matching query: String, in entries: [PrayerEntry]) async throws
    -> [PrayerEntry]
  {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !entries.isEmpty else { return [] }
    #if canImport(FoundationModels)
      let pool = Array(entries.prefix(50))
      let session = LanguageModelSession(instructions: searchSystemPrompt)
      let response = try await session.respond(
        to: searchPrompt(query: trimmed, entries: pool), generating: SearchMatches.self)
      return response.content.indices
        .filter { $0 >= 0 && $0 < pool.count }
        .map { pool[$0] }
    #else
      // FoundationModels absent du SDK : recherche sémantique indisponible, l'appelant retombe
      // sur la recherche textuelle locale.
      return []
    #endif
  }

  #if canImport(FoundationModels)
    // MARK: Prompts

    private var reflectionSystemPrompt: String {
      """
      Tu es un assistant spirituel discret dans une application de prière chrétienne. \
      Tu aides l'utilisateur à réfléchir avant de prier en posant des questions ouvertes, \
      courtes et personnelles — jamais des prières toutes faites. \
      Tes questions invitent à l'introspection sincère et, quand des prières passées \
      sont disponibles, s'appuient sur ce que l'utilisateur a déjà confié. \
      Tu n'enseignes rien, tu ne cites jamais l'Écriture et tu n'apportes aucune \
      interprétation ou précision théologique : tu te limites à des questions ouvertes. \
      Réponds uniquement en français.
      """
    }

    private var searchSystemPrompt: String {
      """
      Tu es un moteur de recherche sémantique sur le journal de prière de l'utilisateur. \
      À partir d'une requête en langage naturel, tu identifies les prières dont le sens \
      correspond, même sans mots identiques. Tu ne juges pas, tu n'interprètes pas \
      spirituellement, tu ne cites pas l'Écriture : tu te limites à retrouver les prières \
      pertinentes par leur sens. Réponds uniquement avec leurs numéros. Réponds en français.
      """
    }

    private func searchPrompt(query: String, entries: [PrayerEntry]) -> String {
      var prompt = "Requête : \(query)\n\nPrières :\n"
      for (index, entry) in entries.enumerated() {
        let dateStr = entry.date.formatted(.dateTime.day().month().year())
        let snippet = entry.text.prefix(200)
        prompt += "[\(index)] \(dateStr) — \(entry.stepTitle) : \(snippet)\n"
      }
      prompt += "\nRenvoie les numéros des prières qui correspondent au sens de la requête."
      return prompt
    }

    private func reflectionPrompt(for step: PrayerStep, recentEntries: [PrayerEntry]) -> String {
      var prompt = "Étape « \(step.title) » : \(step.description)\n\n"

      let pastEntries =
        recentEntries
        .filter { $0.stepTitle == step.title && !$0.text.isEmpty }
        .prefix(3)

      if !pastEntries.isEmpty {
        prompt += "Prières passées de cet utilisateur pour cette étape :\n"
        for entry in pastEntries {
          let dateStr = entry.date.formatted(.dateTime.day().month().year())
          prompt += "- [\(dateStr)] \(entry.text.prefix(300))\n"
        }
        prompt += "\n"
      }

      prompt +=
        "Pose 3 courtes questions de réflexion personnelle (pas des prières) pour aider l'utilisateur à descendre en lui-même avant de prier. Si des prières passées sont disponibles, laisse-les résonner dans tes questions."
      return prompt
    }
  #endif

}
