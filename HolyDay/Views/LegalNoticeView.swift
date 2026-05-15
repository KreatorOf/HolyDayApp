//
//  LegalNoticeView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct LegalNoticeView: View {
    var body: some View {
        List {
            legalSection(
                title: "Éditeur",
                content: "HolyDay est développée et maintenue par Matthias Cadet à titre personnel."
            )

            legalSection(
                title: "Données personnelles",
                content: "HolyDay ne collecte aucune donnée personnelle identifiable. Vos prières et votre journal de prière restent sur votre appareil et ne sont jamais transmis à des serveurs tiers."
            )

            legalSection(
                title: "Roadmap participative",
                content: "Si vous utilisez la fonctionnalité de vote pour la roadmap, un identifiant anonyme propre à votre appareil (UUID généré aléatoirement) est transmis à nos serveurs pour comptabiliser votre vote et prévenir les doublons. Cet identifiant ne permet pas de vous identifier personnellement et n'est associé à aucune autre donnée vous concernant."
            )

            legalSection(
                title: "Notifications",
                content: "Si vous activez les rappels de prière, l'application utilise les notifications locales d'iOS. Aucune donnée n'est envoyée hors de votre appareil dans ce cadre."
            )

            legalSection(
                title: "Contenu biblique",
                content: "Les versets bibliques utilisés dans l'application sont issus de traductions françaises dans le domaine public (Louis Segond 1910)."
            )

            legalSection(
                title: "Propriété intellectuelle",
                content: "L'interface, les icônes et le code source de HolyDay sont protégés par le droit d'auteur. Toute reproduction sans autorisation est interdite."
            )

            legalSection(
                title: "Responsabilité",
                content: "L'application est fournie sans garantie d'aucune sorte. L'éditeur décline toute responsabilité en cas d'utilisation inappropriée."
            )

            legalSection(
                title: "Contact",
                content: "matthias.cadet25@gmail.com"
            )

            Section {
                Text("Dernière mise à jour : mai 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Mentions légales")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legalSection(title: String, content: String) -> some View {
        Section(title) {
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        LegalNoticeView()
    }
}
