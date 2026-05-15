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
    @Guide(description: "3 short open-ended questions in French to help the user reflect personally before writing their prayer for this specific step")
    @Guide(.count(3))
    var questions: [String]
}

@Generable
struct JournalInsight {
    @Guide(description: "3 recurring spiritual themes detected across the prayers, as short concise phrases in French")
    @Guide(.count(3))
    var themes: [String]

    @Guide(description: "2 encouraging personal observations about the spiritual journey based on what was actually written, in French")
    @Guide(.count(2))
    var observations: [String]

    @Guide(description: "Short French phrases describing past supplications that seem to match later gratitude entries, suggesting answered prayers. Empty array if none are clearly identifiable.")
    var answeredPrayers: [String]
}

// MARK: - Service

final class AIAssistantService {
    static let shared = AIAssistantService()

    private init() {}

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // MARK: Reflection questions

    func generateReflectionQuestions(for step: PrayerStep) async throws -> [String] {
        let session = LanguageModelSession(instructions: reflectionSystemPrompt)
        let prompt = "Étape « \(step.title) » : \(step.description)\n\nPose 3 courtes questions de réflexion personnelle (pas des prières) pour aider l'utilisateur à descendre en lui-même avant de prier."
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

    enum AnalysisError: Error {
        case notEnoughEntries
    }

    // MARK: Prompts

    private var reflectionSystemPrompt: String {
        """
        Tu es un assistant spirituel discret dans une application de prière chrétienne. \
        Tu aides l'utilisateur à réfléchir avant de prier en posant des questions ouvertes, \
        courtes et personnelles — jamais des prières toutes faites. \
        Tes questions invitent à l'introspection sincère. Réponds uniquement en français.
        """
    }

    private var journalSystemPrompt: String {
        """
        Tu es un assistant spirituel dans une application de prière chrétienne. \
        Tu analyses les prières écrites par l'utilisateur pour l'aider à prendre du recul \
        sur son cheminement. Tu identifies des thèmes récurrents, des tendances et des prières \
        potentiellement exaucées (quand une supplication passée trouve écho dans une reconnaissance ultérieure). \
        Tu es bienveillant et encourageant. Réponds en français.
        """
    }

    private func journalPrompt(from entries: [PrayerEntry]) -> String {
        let recent = entries.prefix(40)
        let lines = recent.compactMap { entry -> String? in
            guard !entry.text.isEmpty else { return nil }
            let dateStr = entry.date.formatted(.dateTime.day().month())
            // Truncate each entry to avoid exhausting the model context
            let truncated = entry.text.prefix(500)
            return "[\(dateStr) — \(entry.stepTitle)] \(truncated)"
        }
        let summary = lines.joined(separator: "\n\n")
        return "Voici les prières récentes de l'utilisateur :\n\n\(summary)\n\nAnalyse ces prières et génère des insights spirituels bienveillants."
    }
}
