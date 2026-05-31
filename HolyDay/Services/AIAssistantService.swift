//
//  AIAssistantService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
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
struct JournalInsight {
  @Guide(
    description: """
      Exactly 3 recurring spiritual themes DIRECTLY DETECTED in the prayer texts provided. \
      Never write generic themes like 'foi' or 'confiance' in isolation — \
      always anchor them in what this specific user actually wrote. \
      Always in French. Must be specific to this user's actual words.
      """,
    .count(3)
  )
  var themes: [String]

  @Guide(
    description: """
      Exactly 2 encouraging and personal observations about this user's spiritual journey, \
      grounded in concrete patterns observed across the prayer texts. \
      Focus on evolution over time, emotional texture, or prayer depth. \
      Never generic encouragements — always tied to something actually written. \
      In French.
      """,
    .count(2)
  )
  var observations: [String]

  @Guide(
    description: """
      Identify supplication→thanksgiving correlations: cases where a specific request \
      in a Confession or Supplication entry at an earlier date finds an explicit echo \
      in a later Thanksgiving (Action de grâce) entry. \
      Format each as: 'Demande de [X] → Remerciement pour [Y]'. \
      Return an empty array if no clear correlation exists — do not invent connections. \
      In French.
      """)
  var answeredPrayers: [String]
}

@Generable
struct DetectedIntentions {
  @Guide(
    description: """
      Les sujets de prière concrets explicitement mentionnés dans le texte : \
      personnes, situations, demandes pour lesquelles l'utilisateur prie. \
      N'invente rien, n'ajoute aucune interprétation. Formule chaque sujet en \
      2 à 6 mots, tels qu'exprimés par l'utilisateur. Liste vide si aucun sujet clair.
      """)
  var intentions: [String]
}

@Generable
struct MonthlyRecap {
  @Guide(
    description: """
      Un court récit chaleureux et personnel (2 à 3 phrases, 2e personne « tu ») qui reflète \
      le cheminement de prière de l'utilisateur ce mois-ci, uniquement à partir de ses \
      propres mots et tendances. Aucune citation de l'Écriture, aucune interprétation \
      théologique, aucun enseignement.
      """)
  var narrative: String

  @Guide(
    description: """
      1 à 3 thèmes récurrents observés dans les prières du mois, formulés en quelques mots, \
      ancrés dans le texte réel de l'utilisateur.
      """)
  var themes: [String]
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

// MARK: - Service

final class AIAssistantService {
  static let shared = AIAssistantService()

  private init() {}

  // MARK: Reflection questions

  func generateReflectionQuestions(for step: PrayerStep, recentEntries: [PrayerEntry] = [])
    async throws -> [String]
  {
    let session = LanguageModelSession(instructions: reflectionSystemPrompt)
    let prompt = reflectionPrompt(for: step, recentEntries: recentEntries)
    let response = try await session.respond(to: prompt, generating: ReflectionQuestions.self)
    return response.content.questions
  }

  // MARK: Journal analysis

  func analyzeJournal(entries: [PrayerEntry]) async throws -> JournalInsight {
    guard !entries.isEmpty else { throw AnalysisError.notEnoughEntries }
    let session = LanguageModelSession(instructions: journalSystemPrompt)
    let prompt = journalPrompt(from: entries)
    let response = try await session.respond(to: prompt, generating: JournalInsight.self)
    return response.content
  }

  // MARK: Intention detection

  func detectIntentions(in text: String) async throws -> [String] {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let session = LanguageModelSession(instructions: intentionDetectionPrompt)
    let response = try await session.respond(to: trimmed, generating: DetectedIntentions.self)
    return response.content.intentions
  }

  // MARK: Listening companion

  func makeCompanionSession() -> LanguageModelSession {
    LanguageModelSession(instructions: companionSystemPrompt)
  }

  private var companionSystemPrompt: String {
    """
    Tu es un compagnon d'écoute bienveillant dans une application de prière. \
    Ton rôle est d'aider la personne à mettre des mots sur ce qu'elle porte, \
    uniquement en posant des questions ouvertes et en reformulant ses propres \
    paroles avec douceur. \
    Règles absolues : tu ne cites jamais l'Écriture, tu n'enseignes rien, tu \
    n'apportes aucune interprétation ni réponse théologique, tu ne pries pas à \
    sa place, et tu ne prétends jamais parler au nom de Dieu. \
    Tu restes bref (1 à 3 phrases), chaleureux, et tu termines souvent par une \
    question douce qui aide à approfondir. Réponds en français.
    """
  }

  // MARK: Monthly recap

  func monthlyRecap(entries: [PrayerEntry]) async throws -> MonthlyRecap {
    guard entries.count >= 2 else { throw AnalysisError.notEnoughEntries }
    let session = LanguageModelSession(instructions: monthlyRecapSystemPrompt)
    let response = try await session.respond(
      to: journalPrompt(from: entries), generating: MonthlyRecap.self)
    return response.content
  }

  // MARK: Semantic search

  func searchEntries(matching query: String, in entries: [PrayerEntry]) async throws
    -> [PrayerEntry]
  {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !entries.isEmpty else { return [] }
    let pool = Array(entries.prefix(50))
    let session = LanguageModelSession(instructions: searchSystemPrompt)
    let response = try await session.respond(
      to: searchPrompt(query: trimmed, entries: pool), generating: SearchMatches.self)
    return response.content.indices
      .filter { $0 >= 0 && $0 < pool.count }
      .map { pool[$0] }
  }

  enum AnalysisError: Error {
    case notEnoughEntries
  }

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

  private var monthlyRecapSystemPrompt: String {
    """
    Tu rédiges un court récap personnel et chaleureux du mois de prière de l'utilisateur, \
    en reflétant uniquement ses propres mots et tendances : récurrences, évolutions, \
    sujets confiés, exaucements qu'il a notés. Tu ne cites jamais l'Écriture, tu n'enseignes \
    rien, tu n'apportes aucune interprétation théologique. Tu observes avec bienveillance, \
    à la 2e personne. Réponds en français.
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

  private var intentionDetectionPrompt: String {
    """
    Tu extrais les sujets de prière concrets (personnes, situations, demandes) \
    explicitement mentionnés dans le texte d'une prière. \
    Tu n'inventes rien, tu n'ajoutes aucune interprétation, tu ne cites pas l'Écriture. \
    Tu te limites à reformuler brièvement ce que l'utilisateur a écrit. Réponds en français.
    """
  }

  private var journalSystemPrompt: String {
    """
    Tu es un assistant spirituel dans une application de prière chrétienne structurée \
    selon la méthode ACTS (Adoration, Confession, Action de grâce, Supplication). \
    Définitions des étapes : \
    • Adoration : louange et contemplation de Dieu pour ce qu'Il est. \
    • Confession : reconnaissance sincère de ses fautes et manquements. \
    • Action de grâce : remerciements pour les bénédictions reçues. \
    • Supplication : demandes pour soi-même et pour les autres. \
    Tu analyses les prières écrites par l'utilisateur pour l'aider à prendre du recul \
    sur son cheminement. Tu identifies des thèmes récurrents ancrés dans le texte réel, \
    des tendances personnelles, et des corrélations supplication→gratitude (prières potentiellement exaucées). \
    Tu reflètes uniquement les mots de l'utilisateur : tu ne cites jamais l'Écriture \
    et tu n'ajoutes aucune interprétation ou enseignement théologique. \
    Tu es bienveillant, précis et encourageant. Réponds en français.
    """
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

  private func journalPrompt(from entries: [PrayerEntry]) -> String {
    let selected = stratifiedEntries(from: entries)

    let prayedDays = Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    let dateRange: String = {
      guard let first = entries.last?.date, let last = entries.first?.date else { return "" }
      let from = first.formatted(.dateTime.day().month().year())
      let to = last.formatted(.dateTime.day().month().year())
      return "\(from) au \(to)"
    }()

    var prompt = """
      Données : \(entries.count) entrées, \(prayedDays) jours de prière distincts\
      \(dateRange.isEmpty ? "" : " (\(dateRange))").
      Entrées analysées : \(selected.count) (échantillon représentatif).

      Prières de l'utilisateur :

      """

    let lines = selected.compactMap { entry -> String? in
      guard !entry.text.isEmpty else { return nil }
      let dateStr = entry.date.formatted(.dateTime.day().month().year())
      let truncated = entry.text.prefix(500)
      return "[\(dateStr) — \(entry.stepTitle)] \(truncated)"
    }
    prompt += lines.joined(separator: "\n\n")
    prompt +=
      "\n\nAnalyse ces prières et génère des insights spirituels bienveillants et personnalisés."
    return prompt
  }

  // Stratified sampling: 20 most recent + 1 representative per older week
  private func stratifiedEntries(from entries: [PrayerEntry]) -> [PrayerEntry] {
    let withText = entries.filter { !$0.text.isEmpty }
    let recent = Array(withText.prefix(20))
    let older = Array(withText.dropFirst(20))

    let weeklyRepresentatives: [PrayerEntry] = Dictionary(
      grouping: older,
      by: { Calendar.current.component(.weekOfYear, from: $0.date) }
    )
    .values
    .compactMap { group in
      // Pick the entry with the longest text as the most informative
      group.max(by: { $0.text.count < $1.text.count })
    }

    return (recent + weeklyRepresentatives).sorted { $0.date > $1.date }
  }
}
