//
//  Verse.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

struct Verse: Identifiable, Codable {
    let id: UUID
    let text: String
    let reference: String
    let book: String
    let chapter: Int
    let verse: Int

    init(id: UUID = UUID(), text: String, reference: String, book: String, chapter: Int, verse: Int) {
        self.id = id
        self.text = text
        self.reference = reference
        self.book = book
        self.chapter = chapter
        self.verse = verse
    }
}
