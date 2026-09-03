//
//  WhatsNewView.swift
//  HolyDay
//

import SwiftUI

/// Nouveautés présentées une fois après chaque mise à jour. Volontairement sans action secondaire :
/// l'écran informe, il ne demande rien. Une seule sortie, plus le geste de fermeture système.
struct WhatsNewView: View {
  let releases: [ReleaseNote]
  var onDismiss: () -> Void

  /// Vrai quand plusieurs versions sont rattrapées d'un coup : on montre alors le numéro de version
  /// devant chaque groupe, sinon il reste dans l'en-tête.
  private var showsVersionHeaders: Bool { releases.count > 1 }

  var body: some View {
    ZStack {
      AppBackground()

      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          header

          ForEach(releases) { release in
            VStack(alignment: .leading, spacing: 22) {
              if showsVersionHeaders {
                Text(versionLabel(release.version))
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(AppTheme.textTertiary)
                  .textCase(.uppercase)
                  .accessibilityAddTraits(.isHeader)
              }

              ForEach(release.items) { item in
                itemRow(item)
              }
            }
          }
        }
        .padding(.horizontal, 28)
        .padding(.top, 34)
        .padding(.bottom, 24)
      }
      .scrollIndicators(.hidden)
    }
    .safeAreaInset(edge: .bottom) {
      continueButton
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    // Le contenu défile avant que la feuille ne s'agrandisse : sur une liste courte, l'utilisateur
    // lit sans que le geste ne redimensionne la feuille sous son doigt.
    .presentationContentInteraction(.scrolls)
  }

  // MARK: - Header

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("whatsnew.title")
        .font(.system(.largeTitle, design: .serif, weight: .bold).italic())
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityAddTraits(.isHeader)

      if !showsVersionHeaders, let version = releases.first?.version {
        Text(versionLabel(version))
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Item

  private func itemRow(_ item: ReleaseNote.Item) -> some View {
    HStack(alignment: .top, spacing: 16) {
      ZStack {
        Circle()
          .fill(item.color.opacity(0.12))
          .frame(width: 44, height: 44)
        Image(systemName: item.icon)
          .font(.system(size: 19, weight: .medium))
          .foregroundStyle(item.color)
      }
      .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text(item.titleKey)
          .font(.headline)
          .foregroundStyle(AppTheme.textPrimary)
        Text(item.bodyKey)
          .font(.subheadline)
          .foregroundStyle(AppTheme.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    // Une seule annonce VoiceOver par nouveauté, titre puis description, plutôt que deux éléments
    // à parcourir séparément.
    .accessibilityElement(children: .combine)
  }

  // MARK: - Action

  private var continueButton: some View {
    Button(action: onDismiss) {
      Text("whatsnew.continue")
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(AppTheme.adorationPurple, in: RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 28)
    .padding(.bottom, 28)
    .padding(.top, 12)
    .background(.ultraThinMaterial)
  }

  // MARK: - Helpers

  private func versionLabel(_ version: String) -> String {
    String(format: String(localized: "whatsnew.version"), version)
  }
}

#Preview("Une version") {
  Color.black
    .sheet(isPresented: .constant(true)) {
      WhatsNewView(releases: ReleaseNotesCatalog.all, onDismiss: {})
    }
}
