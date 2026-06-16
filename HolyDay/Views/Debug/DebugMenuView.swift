//
//  DebugMenuView.swift
//  HolyDay
//
//  Page développeur (DEBUG uniquement) : inspecter l'état, réinitialiser à la carte,
//  injecter des données de démo. Poussée depuis Réglages → section « Développeur ».
//

#if DEBUG

  import SwiftData
  import SwiftUI
  import TipKit

  struct DebugMenuView: View {
    @Environment(\.modelContext) private var context

    @AppStorage("holyday.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("holyday.userName") private var userName = ""
    @AppStorage("holyday.colorScheme") private var colorSchemePreference = "system"

    @Query private var prayers: [PrayerEntry]
    @Query private var intentions: [PrayerIntention]

    @State private var streak = StreakService.shared
    @State private var tip = TipService.shared
    @State private var showNukeConfirmation = false
    @State private var toast: String?

    var body: some View {
      List {
        stateSection
        resetSection
        seedSection
        nukeSection
      }
      .navigationTitle("🛠 Debug")
      .navigationBarTitleDisplayMode(.inline)
      .overlay(alignment: .bottom) { toastView }
      .confirmationDialog(
        "Tout réinitialiser ?", isPresented: $showNukeConfirmation, titleVisibility: .visible
      ) {
        Button("Tout effacer", role: .destructive, action: nuke)
        Button("Annuler", role: .cancel) {}
      } message: {
        Text("Prières, intentions, série, prénom, thème, onboarding et badge supporter.")
      }
    }

    // MARK: - État

    private var stateSection: some View {
      Section("État") {
        infoRow("Onboarding terminé", hasCompletedOnboarding ? "oui" : "non")
        infoRow("Prénom", userName.isEmpty ? "—" : userName)
        infoRow("Série actuelle", "\(streak.currentStreak)")
        infoRow("Record", "\(streak.bestStreak)")
        infoRow("Gels disponibles", "\(streak.freezesAvailable)")
        infoRow("Jours priés", "\(streak.totalPrayedDays)")
        infoRow("Prières", "\(prayers.count)")
        infoRow("Intentions", "\(intentions.count)")
        infoRow("IA disponible", AIAssistantService.shared.isAvailable ? "oui" : "non")
        Toggle(
          "Supporter (premium)",
          isOn: Binding(
            get: { tip.hasTipped },
            set: { tip.debugSetSupporter($0) }
          )
        )
      }
    }

    // MARK: - Réinitialiser

    private var resetSection: some View {
      Section("Réinitialiser") {
        // Parcours fidèle (étape par étape) : nécessite un reset du datastore TipKit, qui ne peut
        // se faire qu'avant configure() → au prochain lancement à froid.
        actionRow("Relancer l'onboarding + parcours", systemName: "arrow.counterclockwise") {
          UserDefaults.standard.set(true, forKey: "holyday.debug.resetTips")
          hasCompletedOnboarding = false
          flash("Onboarding relancé — relance l'app pour le parcours")
        }
        // Aperçu rapide : force tous les tips d'un coup (ignore l'ordre des étapes).
        actionRow("Forcer tous les tips (aperçu)", systemName: "lightbulb") {
          Tips.showAllTipsForTesting()
          flash("Tips forcés (hors séquence)")
        }
        actionRow("Masquer les tips", systemName: "lightbulb.slash") {
          Tips.hideAllTipsForTesting()
          flash("Tips masqués")
        }
        actionRow("Réinitialiser la série", systemName: "flame") {
          DebugActions.resetStreak()
          flash("Série remise à zéro")
        }
        actionRow("Vider les prières", systemName: "book.closed", role: .destructive) {
          DebugActions.clearPrayers(in: context)
          flash("Prières supprimées")
        }
        actionRow("Vider les intentions", systemName: "list.bullet", role: .destructive) {
          DebugActions.clearIntentions(in: context)
          flash("Intentions supprimées")
        }
      }
    }

    // MARK: - Données de démo

    private var seedSection: some View {
      Section("Données de démo") {
        actionRow("Générer 14 jours de prières", systemName: "wand.and.stars") {
          DebugActions.seedDemoPrayers(in: context)
          flash("Données de démo créées")
        }
      }
    }

    // MARK: - Zone rouge

    private var nukeSection: some View {
      Section {
        actionRow("Tout réinitialiser", systemName: "trash", role: .destructive) {
          showNukeConfirmation = true
        }
      }
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, _ value: String) -> some View {
      HStack {
        Text(label)
        Spacer()
        Text(value)
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }
    }

    private func actionRow(
      _ title: String, systemName: String, role: ButtonRole? = nil, action: @escaping () -> Void
    ) -> some View {
      Button(role: role, action: action) {
        Label(title, systemImage: systemName)
      }
    }

    @ViewBuilder private var toastView: some View {
      if let toast {
        Text(toast)
          .font(.subheadline.weight(.semibold))
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .glassEffect(.regular, in: Capsule())
          .padding(.bottom, 24)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }

    private func flash(_ message: String) {
      withAnimation { toast = message }
      Task {
        try? await Task.sleep(for: .seconds(1.6))
        withAnimation { toast = nil }
      }
    }

    private func nuke() {
      DebugActions.clearPrayers(in: context)
      DebugActions.clearIntentions(in: context)
      DebugActions.resetStreak()
      tip.debugSetSupporter(false)
      userName = ""
      colorSchemePreference = "system"
      UserDefaults.standard.set(true, forKey: "holyday.debug.resetTips")
      hasCompletedOnboarding = false
      flash("Tout réinitialisé")
    }
  }

  #Preview {
    NavigationStack { DebugMenuView() }
      .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
  }

#endif
