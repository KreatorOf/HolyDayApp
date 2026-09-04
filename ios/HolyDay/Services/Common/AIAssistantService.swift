//
//  AIAssistantService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation

// FoundationModels (modèle on-device Apple Intelligence) n'existe qu'à partir d'iOS 26, alors que
// l'app cible iOS 18. Double garde nécessaire : `canImport` couvre l'absence du framework dans le
// SDK de compilation, `@available` / `#available` couvrent l'exécution sur un appareil iOS 18-25 où
// le symbole existe dans le SDK mais pas sur le système. Les trois fonctionnalités qui en dépendent
// (titre de prière, questions de réflexion, recherche sémantique) sont facultatives : partout où le
// modèle manque, on dégrade silencieusement vers le repli de l'appelant.
#if canImport(FoundationModels)
  import FoundationModels

  // MARK: - Generable output types

  @available(iOS 26.0, *)
  @Generable
  struct ReflectionQuestions {
    @Guide(
      description:
        "3 short, open-ended questions helping the user reflect personally before writing their prayer for this step. Write them in the language required by the instructions.",
      .count(3)
    )
    var questions: [String]
  }

  @available(iOS 26.0, *)
  @Generable
  struct SearchMatches {
    @Guide(
      description: """
        The numbers of the prayers whose meaning matches the user's query, even without \
        identical words. Empty list if none match.
        """)
    var indices: [Int]
  }

  @available(iOS 26.0, *)
  @Generable
  struct PrayerTitle {
    @Guide(
      description: """
        A short 2-to-5-word title summarising the prayer's theme: neutral, factual, no judgement, \
        no spiritual interpretation, no quotes, no trailing punctuation. Write it in the language \
        required by the instructions.
        """)
    var title: String
  }
#endif

// MARK: - Service

final class AIAssistantService {
  static let shared = AIAssistantService()

  private init() {}

  /// Le modèle on-device est-il prêt à l'emploi ? `false` si le système est antérieur à iOS 26, si
  /// le framework est absent du SDK, si l'appareil n'est pas éligible, ou si Apple Intelligence
  /// n'est pas activé/téléchargé.
  var isAvailable: Bool {
    #if canImport(FoundationModels)
      guard #available(iOS 26.0, *) else { return false }
      if case .available = SystemLanguageModel.default.availability { return true }
      return false
    #else
      return false
    #endif
  }

  // MARK: Prayer title

  /// Suggère un titre court pour une prière libre. Renvoie `nil` (et l'appelant garde son repli) si
  /// le modèle est indisponible ou si la génération échoue — y compris sur violation de garde-fou,
  /// fréquente sur des textes intimes : on dégrade alors silencieusement, sans erreur visible.
  func generateTitle(for text: String) async -> String? {
    #if canImport(FoundationModels)
      guard #available(iOS 26.0, *) else { return nil }
      guard case .available = SystemLanguageModel.default.availability else { return nil }
      let french = AppLanguage.isFrench
      do {
        let session = LanguageModelSession(instructions: Self.titleSystemPrompt(french: french))
        let options = GenerationOptions(temperature: 0.3, maximumResponseTokens: 24)
        let response = try await session.respond(
          to: Self.titlePrompt(for: text, french: french), generating: PrayerTitle.self,
          options: options)
        let title = response.content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
      } catch {
        return nil
      }
    #else
      return nil
    #endif
  }

  // MARK: Reflection questions

  func generateReflectionQuestions(for step: PrayerStep, recentEntries: [PrayerEntry] = [])
    async throws -> [String]
  {
    #if canImport(FoundationModels)
      // iOS 18-25 : l'aide à la réflexion est facultative, on dégrade silencieusement vers aucune
      // question plutôt que d'exposer une erreur pour une fonctionnalité d'appoint.
      guard #available(iOS 26.0, *) else { return [] }
      guard case .available = SystemLanguageModel.default.availability else { return [] }
      let french = AppLanguage.isFrench
      let session = LanguageModelSession(instructions: Self.reflectionSystemPrompt(french: french))
      let prompt = Self.reflectionPrompt(
        for: step, recentEntries: recentEntries, french: french)
      let response = try await session.respond(to: prompt, generating: ReflectionQuestions.self)
      return response.content.questions
    #else
      // FoundationModels absent du SDK : même dégradation.
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
      // Système antérieur à iOS 26, appareil non éligible ou Apple Intelligence désactivé : on
      // n'ouvre pas de session pour rien, l'appelant retombe sur la recherche textuelle locale.
      guard #available(iOS 26.0, *) else { return [] }
      guard case .available = SystemLanguageModel.default.availability else { return [] }
      let pool = Array(entries.prefix(50))
      let french = AppLanguage.isFrench
      let session = LanguageModelSession(instructions: Self.searchSystemPrompt(french: french))
      let response = try await session.respond(
        to: Self.searchPrompt(query: trimmed, entries: pool, french: french),
        generating: SearchMatches.self)
      return response.content.indices
        .filter { $0 >= 0 && $0 < pool.count }
        .map { pool[$0] }
    #else
      // FoundationModels absent du SDK : recherche sémantique indisponible, l'appelant retombe
      // sur la recherche textuelle locale.
      return []
    #endif
  }

  // MARK: Prompts
  // Paramétrés par la langue plutôt que figés : l'app parle français ou anglais, et le modèle doit
  // suivre. Ce sont de simples chaînes, gardées hors des `#if` de disponibilité — les compiler sur
  // toutes les versions évite de dupliquer les gardes autour de simples accès mémoire.
  // `internal` (et non `private`) pour être vérifiables par les tests : c'est précisément l'absence
  // de couverture ici qui a laissé passer des réponses françaises sur une app en anglais.

  static func reflectionSystemPrompt(french: Bool) -> String {
    french
      ? """
      Tu es un assistant spirituel discret dans une application de prière chrétienne. \
      Tu aides l'utilisateur à réfléchir avant de prier en posant des questions ouvertes, \
      courtes et personnelles — jamais des prières toutes faites. \
      Tes questions invitent à l'introspection sincère et, quand des prières passées \
      sont disponibles, s'appuient sur ce que l'utilisateur a déjà confié. \
      Tu n'enseignes rien, tu ne cites jamais l'Écriture et tu n'apportes aucune \
      interprétation ou précision théologique : tu te limites à des questions ouvertes. \
      Réponds uniquement en français.
      """
      : """
      You are a discreet spiritual assistant inside a Christian prayer app. \
      You help the user reflect before praying by asking short, open-ended, personal \
      questions — never ready-made prayers. \
      Your questions invite honest introspection and, when past prayers are available, \
      draw on what the user has already confided. \
      You teach nothing, you never quote Scripture and you offer no theological \
      interpretation or clarification: you limit yourself to open questions. \
      Answer in English only.
      """
  }

  static func titleSystemPrompt(french: Bool) -> String {
    french
      ? """
      Tu titres des prières personnelles dans une application de prière chrétienne. \
      À partir du texte d'une prière, tu proposes un titre court (2 à 5 mots), neutre et \
      factuel, qui en résume le thème. Tu ne juges pas, tu n'interprètes pas spirituellement, \
      tu ne cites pas l'Écriture. Pas de guillemets, pas de ponctuation finale. \
      Réponds uniquement en français.
      """
      : """
      You title personal prayers inside a Christian prayer app. \
      From the text of a prayer, you propose a short title (2 to 5 words), neutral and \
      factual, summarising its theme. You do not judge, you do not interpret spiritually, \
      you do not quote Scripture. No quotation marks, no trailing punctuation. \
      Answer in English only.
      """
  }

  static func searchSystemPrompt(french: Bool) -> String {
    french
      ? """
      Tu es un moteur de recherche sémantique sur le journal de prière de l'utilisateur. \
      À partir d'une requête en langage naturel, tu identifies les prières dont le sens \
      correspond, même sans mots identiques. Tu ne juges pas, tu n'interprètes pas \
      spirituellement, tu ne cites pas l'Écriture : tu te limites à retrouver les prières \
      pertinentes par leur sens. Réponds uniquement avec leurs numéros.
      """
      : """
      You are a semantic search engine over the user's prayer journal. \
      From a natural-language query, you identify the prayers whose meaning matches, \
      even without identical words. You do not judge, you do not interpret spiritually, \
      you do not quote Scripture: you limit yourself to finding the relevant prayers by \
      meaning. Answer with their numbers only.
      """
  }

  static func titlePrompt(for text: String, french: Bool) -> String {
    let body = text.prefix(800)
    return french
      ? "Prière :\n\(body)\n\nDonne un titre court résumant le thème."
      : "Prayer:\n\(body)\n\nGive a short title summarising the theme."
  }

  static func searchPrompt(query: String, entries: [PrayerEntry], french: Bool) -> String {
    var prompt = french ? "Requête : \(query)\n\nPrières :\n" : "Query: \(query)\n\nPrayers:\n"
    for (index, entry) in entries.enumerated() {
      let dateStr = entry.date.formatted(.dateTime.day().month().year())
      let snippet = entry.text.prefix(200)
      prompt += "[\(index)] \(dateStr) — \(entry.displayTitle) : \(snippet)\n"
    }
    prompt +=
      french
      ? "\nRenvoie les numéros des prières qui correspondent au sens de la requête."
      : "\nReturn the numbers of the prayers matching the meaning of the query."
    return prompt
  }

  static func reflectionPrompt(for step: PrayerStep, recentEntries: [PrayerEntry], french: Bool)
    -> String
  {
    var prompt =
      french
      ? "Étape « \(step.title) » : \(step.description)\n\n"
      : "Step “\(step.title)”: \(step.description)\n\n"

    let pastEntries =
      recentEntries
      .filter { $0.stepTitle == step.title && !$0.text.isEmpty }
      .prefix(3)

    if !pastEntries.isEmpty {
      prompt +=
        french
        ? "Prières passées de cet utilisateur pour cette étape :\n"
        : "This user's past prayers for this step:\n"
      for entry in pastEntries {
        let dateStr = entry.date.formatted(.dateTime.day().month().year())
        prompt += "- [\(dateStr)] \(entry.text.prefix(300))\n"
      }
      prompt += "\n"
    }

    prompt +=
      french
      ? "Pose 3 courtes questions de réflexion personnelle (pas des prières) pour aider l'utilisateur à descendre en lui-même avant de prier. Si des prières passées sont disponibles, laisse-les résonner dans tes questions."
      : "Ask 3 short personal reflection questions (not prayers) to help the user look inward before praying. If past prayers are available, let them echo in your questions."
    return prompt
  }
}
