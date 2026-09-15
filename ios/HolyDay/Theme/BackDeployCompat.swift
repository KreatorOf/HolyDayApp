//
//  BackDeployCompat.swift
//  HolyDay
//
//  Created by Matthias Cadet on 25/08/2026.
//

import SwiftUI
import TipKit

// Équivalents iOS 18 des API SwiftUI/TipKit introduites en iOS 26. Le verre liquide a sa propre
// couche (`GlassCompat`) ; ici on regroupe le reste, à savoir le bouton de fermeture système et le
// pilotage du parcours de découverte.

// MARK: - Close button

/// Bouton de fermeture d'une feuille modale.
///
/// `Button(role: .close)` (glyphe fourni et positionné par le système) n'existe qu'à partir
/// d'iOS 26 ; en dessous on redessine le même « xmark » à la main.
struct AppCloseButton: View {
  private let action: () -> Void

  init(action: @escaping () -> Void) {
    self.action = action
  }

  var body: some View {
    if #available(iOS 26.0, *) {
      Button(role: .close, action: action)
    } else {
      Button(action: action) {
        Image(systemName: "xmark")
          .font(.body.weight(.semibold))
      }
      .accessibilityLabel(Text("common.close"))
    }
  }
}

// MARK: - Cancel button

/// Bouton d'annulation d'une feuille modale.
///
/// Même contrainte que `AppCloseButton` : l'initialiseur sans libellé (`Button(role:action:)`), qui
/// laisse le système fournir le texte, n'existe qu'à partir d'iOS 26. En dessous on fournit le
/// libellé localisé nous-mêmes.
struct AppCancelButton: View {
  private let action: () -> Void

  init(action: @escaping () -> Void) {
    self.action = action
  }

  var body: some View {
    if #available(iOS 26.0, *) {
      Button(role: .cancel, action: action)
    } else {
      Button("common.cancel", role: .cancel, action: action)
    }
  }
}

// MARK: - Back button

/// Bouton de retour (flèche), pour les feuilles modales qui préfèrent ce geste au « Annuler »
/// textuel — même emplacement de barre d'outils que `AppCloseButton`/`AppCancelButton`.
struct AppBackButton: View {
  private let action: () -> Void

  init(action: @escaping () -> Void) {
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Image(systemName: "chevron.left")
        .font(.body.weight(.semibold))
    }
    .accessibilityLabel(Text("common.back"))
  }
}

// MARK: - Scroll edge effect

extension View {
  /// Retire le voile translucide qu'iOS 26 pose au bord haut des vues défilantes.
  ///
  /// À partir d'iOS 26, `ScrollView`/`List` estompent automatiquement leur contenu sous la barre de
  /// navigation. Les écrans de l'app passent leur contenu sous une barre déjà transparente
  /// (`toolbarBackground(.hidden)`) : ce voile venait donc masquer les grands titres de page au lieu
  /// de séparer deux plans. En dessous d'iOS 26 l'effet n'existe pas, la vue est renvoyée telle
  /// quelle.
  @ViewBuilder
  func appTopScrollEdgeEffectHidden() -> some View {
    if #available(iOS 26.0, *) {
      scrollEdgeEffectHidden(true, for: .top)
    } else {
      self
    }
  }
}

// MARK: - Tips

extension View {
  /// Présente un tip du parcours de découverte en reflétant son état d'affichage dans `isPresented`.
  ///
  /// L'app ne force jamais l'affichage : `isPresented` est en lecture seule côté appelant, qui
  /// observe son passage à `false` pour donner l'événement rendant l'étape suivante éligible.
  ///
  /// La surcharge `popoverTip(_:isPresented:…)` est réservée à iOS 26. En dessous on utilise la
  /// surcharge historique et on reconstitue le même signal depuis `statusUpdates` : `available`
  /// pendant que le tip est éligible, `invalidated` dès qu'il est fermé — que ce soit par la croix
  /// ou par un `invalidate(reason:)` explicite de l'app.
  @ViewBuilder
  func appPopoverTip(
    _ tip: some Tip,
    isPresented: Binding<Bool>,
    arrowEdge: Edge = .top
  ) -> some View {
    if #available(iOS 26.0, *) {
      popoverTip(tip, isPresented: isPresented, arrowEdge: arrowEdge)
    } else {
      popoverTip(tip, arrowEdge: arrowEdge)
        .task {
          for await status in tip.statusUpdates {
            switch status {
            case .available: isPresented.wrappedValue = true
            case .invalidated: isPresented.wrappedValue = false
            default: break
            }
          }
        }
    }
  }
}
