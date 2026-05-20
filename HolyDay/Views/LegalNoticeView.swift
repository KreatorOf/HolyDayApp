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
                title: String(localized: "legal.section.publisher"),
                content: String(localized: "legal.section.publisher.content")
            )

            legalSection(
                title: String(localized: "legal.section.data"),
                content: String(localized: "legal.section.data.content")
            )

            legalSection(
                title: String(localized: "legal.section.roadmap"),
                content: String(localized: "legal.section.roadmap.content")
            )

            legalSection(
                title: String(localized: "legal.section.notifications"),
                content: String(localized: "legal.section.notifications.content")
            )

            legalSection(
                title: String(localized: "legal.section.biblical"),
                content: String(localized: "legal.section.biblical.content")
            )

            legalSection(
                title: String(localized: "legal.section.ip"),
                content: String(localized: "legal.section.ip.content")
            )

            legalSection(
                title: String(localized: "legal.section.liability"),
                content: String(localized: "legal.section.liability.content")
            )

            legalSection(
                title: String(localized: "legal.section.contact"),
                content: "matthias.cadet25@gmail.com"
            )

            Section {
                Text("legal.last.update")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Text("legal.nav.title"))
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
