import XCTest

@testable import HolyDay

/// Couvre le contrat de langue des prompts du modèle on-device.
///
/// Ces tests n'appellent jamais le modèle : ils vérifient uniquement que les consignes envoyées
/// portent bien la langue de l'app. C'est précisément ce qui manquait — les prompts étaient
/// entièrement rédigés en français, donc une app en anglais recevait des questions de réflexion,
/// des titres de prière et des résultats de recherche en français.
@MainActor
final class AIAssistantServiceTests: XCTestCase {

  private func step() -> PrayerStep {
    PrayerStep(
      title: "Adoration",
      description: "Loue Dieu pour ce qu'il est",
      icon: "hands.sparkles",
      colorName: "adorationPurple",
      order: 1
    )
  }

  // MARK: - Consignes système

  func test_reflectionSystemPrompt_english_requestsEnglishOnly() {
    let prompt = AIAssistantService.reflectionSystemPrompt(french: false)
    XCTAssertTrue(prompt.contains("Answer in English only"))
    XCTAssertFalse(prompt.contains("français"))
  }

  func test_reflectionSystemPrompt_french_requestsFrenchOnly() {
    let prompt = AIAssistantService.reflectionSystemPrompt(french: true)
    XCTAssertTrue(prompt.contains("Réponds uniquement en français"))
  }

  func test_titleSystemPrompt_english_requestsEnglishOnly() {
    let prompt = AIAssistantService.titleSystemPrompt(french: false)
    XCTAssertTrue(prompt.contains("Answer in English only"))
    XCTAssertFalse(prompt.contains("français"))
  }

  func test_titleSystemPrompt_french_requestsFrenchOnly() {
    XCTAssertTrue(
      AIAssistantService.titleSystemPrompt(french: true).contains("Réponds uniquement en français"))
  }

  func test_searchSystemPrompt_english_hasNoFrenchInstruction() {
    let prompt = AIAssistantService.searchSystemPrompt(french: false)
    XCTAssertTrue(prompt.contains("semantic search engine"))
    XCTAssertFalse(prompt.contains("français"))
  }

  // MARK: - Prompts utilisateur

  func test_titlePrompt_english_usesEnglishLabels() {
    let prompt = AIAssistantService.titlePrompt(for: "Thank you for today.", french: false)
    XCTAssertTrue(prompt.hasPrefix("Prayer:"))
    XCTAssertFalse(prompt.contains("Prière"))
  }

  func test_titlePrompt_french_usesFrenchLabels() {
    let prompt = AIAssistantService.titlePrompt(for: "Merci pour aujourd'hui.", french: true)
    XCTAssertTrue(prompt.hasPrefix("Prière :"))
  }

  func test_reflectionPrompt_english_usesEnglishLabels() {
    let prompt = AIAssistantService.reflectionPrompt(
      for: step(), recentEntries: [], french: false)
    XCTAssertTrue(prompt.hasPrefix("Step "))
    XCTAssertTrue(prompt.contains("Ask 3 short personal reflection questions"))
    XCTAssertFalse(prompt.contains("Pose 3 courtes questions"))
  }

  func test_reflectionPrompt_french_usesFrenchLabels() {
    let prompt = AIAssistantService.reflectionPrompt(
      for: step(), recentEntries: [], french: true)
    XCTAssertTrue(prompt.hasPrefix("Étape "))
    XCTAssertTrue(prompt.contains("Pose 3 courtes questions"))
  }

  func test_searchPrompt_english_usesEnglishLabels() {
    let prompt = AIAssistantService.searchPrompt(query: "gratitude", entries: [], french: false)
    XCTAssertTrue(prompt.hasPrefix("Query: gratitude"))
    XCTAssertTrue(prompt.contains("Return the numbers"))
    XCTAssertFalse(prompt.contains("Requête"))
  }

  func test_searchPrompt_french_usesFrenchLabels() {
    let prompt = AIAssistantService.searchPrompt(query: "gratitude", entries: [], french: true)
    XCTAssertTrue(prompt.hasPrefix("Requête : gratitude"))
  }

  // MARK: - Le bug, en une assertion

  /// Aucune consigne envoyée au modèle en mode anglais ne doit contenir de français.
  func test_noPromptLeaksFrench_whenAppIsInEnglish() {
    let prompts = [
      AIAssistantService.reflectionSystemPrompt(french: false),
      AIAssistantService.titleSystemPrompt(french: false),
      AIAssistantService.searchSystemPrompt(french: false),
      AIAssistantService.titlePrompt(for: "text", french: false),
      AIAssistantService.searchPrompt(query: "q", entries: [], french: false),
      AIAssistantService.reflectionPrompt(for: step(), recentEntries: [], french: false),
    ]
    // Marqueurs de français sans homographe anglais courant.
    let frenchMarkers = ["français", "Réponds", "Prière", "Requête", "Étape", "questions de"]
    for prompt in prompts {
      for marker in frenchMarkers {
        XCTAssertFalse(
          prompt.contains(marker),
          "Le prompt anglais contient « \(marker) » :\n\(prompt.prefix(160))")
      }
    }
  }
}
