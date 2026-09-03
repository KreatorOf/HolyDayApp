import SwiftUI
import XCTest

@testable import HolyDay

@MainActor
final class WhatsNewServiceTests: XCTestCase {

  // Suite isolée par test pour ne jamais toucher aux préférences réelles.
  private func makeDefaults() throws -> UserDefaults {
    let suite = "test.whatsnew.\(UUID().uuidString)"
    return try XCTUnwrap(UserDefaults(suiteName: suite))
  }

  private func note(_ version: String) -> ReleaseNote {
    ReleaseNote(
      version: version,
      items: [
        ReleaseNote.Item(
          icon: "star",
          titleKey: "t",
          bodyKey: "b",
          colorName: "adorationPurple",
          accessibilityTitle: "titre \(version)"
        )
      ]
    )
  }

  private func makeService(
    defaults: UserDefaults,
    version: String,
    catalog: [String]
  ) -> WhatsNewService {
    WhatsNewService(
      defaults: defaults,
      currentVersion: version,
      catalog: catalog.map(note)
    )
  }

  // MARK: - Installation neuve

  func test_freshInstall_afterOnboarding_showsNothing() throws {
    let defaults = try makeDefaults()
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.1"])

    // L'onboarding marque la version courante comme vue avant l'entrée dans l'app.
    service.markSeen()
    service.evaluate()

    XCTAssertNil(service.pending)
  }

  // MARK: - Mise à jour depuis un binaire antérieur à la fonctionnalité

  func test_noRecordedVersion_showsCurrentVersionOnly() throws {
    let defaults = try makeDefaults()
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.0.1", "1.1"])

    service.evaluate()

    XCTAssertEqual(service.pending?.releases.map(\.version), ["1.1"])
  }

  // MARK: - Même version

  func test_sameVersionAlreadySeen_showsNothing() throws {
    let defaults = try makeDefaults()
    defaults.set("1.1", forKey: "holyday.whatsNew.lastSeenVersion")
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.1"])

    service.evaluate()

    XCTAssertNil(service.pending)
  }

  func test_relaunchAfterDismissal_showsNothing() throws {
    let defaults = try makeDefaults()
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.1"])

    service.evaluate()
    XCTAssertNotNil(service.pending)

    service.markSeen()
    service.evaluate()

    XCTAssertNil(service.pending)
  }

  // MARK: - Mise à jour

  func test_upgrade_showsNewVersionNote() throws {
    let defaults = try makeDefaults()
    defaults.set("1.0.1", forKey: "holyday.whatsNew.lastSeenVersion")
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.0.1", "1.1"])

    service.evaluate()

    XCTAssertEqual(service.pending?.releases.map(\.version), ["1.1"])
  }

  func test_skippedVersions_areCaughtUp_newestFirst() throws {
    let defaults = try makeDefaults()
    defaults.set("1.0.1", forKey: "holyday.whatsNew.lastSeenVersion")
    let service = makeService(
      defaults: defaults, version: "1.3", catalog: ["1.0.1", "1.1", "1.2", "1.3"])

    service.evaluate()

    XCTAssertEqual(service.pending?.releases.map(\.version), ["1.3", "1.2", "1.1"])
  }

  func test_notesNewerThanInstalledBinary_areNotShown() throws {
    let defaults = try makeDefaults()
    defaults.set("1.0.1", forKey: "holyday.whatsNew.lastSeenVersion")
    // Le catalogue contient déjà la 1.2 alors que le binaire installé est en 1.1.
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.1", "1.2"])

    service.evaluate()

    XCTAssertEqual(service.pending?.releases.map(\.version), ["1.1"])
  }

  // MARK: - Version sans note

  func test_versionWithoutNote_showsNothingAndAdvancesMarker() throws {
    let defaults = try makeDefaults()
    defaults.set("1.1", forKey: "holyday.whatsNew.lastSeenVersion")
    // 1.2 est installée mais n'a pas de note (correctif purement interne).
    let service = makeService(defaults: defaults, version: "1.2", catalog: ["1.1"])

    service.evaluate()

    XCTAssertNil(service.pending)
    // Le repère avance : sinon la note de 1.3 ressortirait plus tard accompagnée de celle de 1.1.
    XCTAssertEqual(defaults.string(forKey: "holyday.whatsNew.lastSeenVersion"), "1.2")
  }

  // MARK: - Persistance

  func test_markSeen_persistsCurrentVersion() throws {
    let defaults = try makeDefaults()
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.1"])

    service.markSeen()

    XCTAssertEqual(defaults.string(forKey: "holyday.whatsNew.lastSeenVersion"), "1.1")
  }

  func test_reset_clearsMarkerAndReplays() throws {
    let defaults = try makeDefaults()
    let service = makeService(defaults: defaults, version: "1.1", catalog: ["1.1"])
    service.markSeen()

    service.reset()
    service.evaluate()

    XCTAssertEqual(service.pending?.releases.map(\.version), ["1.1"])
  }

  // MARK: - Comparaison de versions

  func test_versionComparison_isNumericNotLexicographic() {
    // Le piège classique : « 1.10 » < « 1.9 » en comparaison de chaînes.
    XCTAssertTrue(WhatsNewService.isVersion("1.10", newerThan: "1.9"))
    XCTAssertTrue(WhatsNewService.isVersion("1.0.1", newerThan: "1.0"))
    XCTAssertTrue(WhatsNewService.isVersion("2.0", newerThan: "1.99"))
    XCTAssertFalse(WhatsNewService.isVersion("1.0", newerThan: "1.0"))
    XCTAssertFalse(WhatsNewService.isVersion("1.0", newerThan: "1.0.1"))
  }

  // MARK: - Catalogue réel

  func test_shippedCatalog_versionsAreUniqueAndItemsNonEmpty() {
    let versions = ReleaseNotesCatalog.all.map(\.version)
    XCTAssertEqual(Set(versions).count, versions.count, "Deux notes pour la même version")
    for note in ReleaseNotesCatalog.all {
      XCTAssertFalse(note.items.isEmpty, "Note vide pour la version \(note.version)")
    }
  }
}
