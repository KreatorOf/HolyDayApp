//
//  HolyDayUITests.swift
//  HolyDayUITests
//
//  Parcours de capture d'écran App Store piloté par `fastlane snapshot`.
//  Le lancement est rendu déterministe côté app par `ScreenshotMode` (voir --uiTestScreenshots).
//

import XCTest

final class HolyDayUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testScreenshots() throws {
    let app = XCUIApplication()
    setupSnapshot(app)
    // Active le mode capture (pas de splash / onboarding / tips) et pré-sélectionne une émotion
    // pour que le verset s'affiche sans dépendre du ruban animé.
    app.launchArguments += ["--uiTestScreenshots", "--screenshotEmotion", "peace"]
    app.launch()

    // 1. Accueil : verset affiché. On laisse la révélation mot à mot se terminer.
    let prayButton = app.buttons["home.prayButton"]
    XCTAssertTrue(prayButton.waitForExistence(timeout: 20), "Écran d'accueil introuvable")
    sleep(3)
    snapshot("01_Home")

    // 2. + 3. Journal et Réglages via la barre d'onglets (index → indépendant de la langue).
    let tabs = app.tabBars.buttons
    if tabs.count >= 3 {
      tabs.element(boundBy: 1).tap()
      sleep(2)
      snapshot("02_Journal")

      tabs.element(boundBy: 2).tap()
      sleep(1)
      snapshot("03_Settings")

      // Retour à l'onglet prière pour la dernière capture.
      tabs.element(boundBy: 0).tap()
      sleep(1)
    }

    // 4. Prière guidée : ouvre le menu « Prier » puis l'option guidée (capturée en dernier, la
    // feuille plein écran n'a pas besoin d'être refermée).
    prayButton.tap()
    let guided = app.buttons["prayer.guided.menuItem"]
    if guided.waitForExistence(timeout: 5) {
      guided.tap()
      sleep(2)
      snapshot("04_GuidedPrayer")
    }
  }
}
