package com.matthiascadet.holyday.data.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import java.util.UUID

/** Équivalent de `VerseTests.swift`. Le round-trip Codable n'a pas d'équivalent testé ici : `Verse` n'est jamais sérialisé en JSON côté Android (pas de persistance/transfert qui en dépende). */
class VerseTest {

    @Test
    fun `init stores all fields`() {
        val verse = Verse(text = "Test", reference = "Jean 3:16", book = "Jean", chapter = 3, verse = 16)
        assertEquals("Test", verse.text)
        assertEquals("Jean 3:16", verse.reference)
        assertEquals("Jean", verse.book)
        assertEquals(3, verse.chapter)
        assertEquals(16, verse.verse)
    }

    @Test
    fun `init generates unique ids`() {
        val v1 = Verse(text = "A", reference = "A 1:1", book = "A", chapter = 1, verse = 1)
        val v2 = Verse(text = "B", reference = "B 1:1", book = "B", chapter = 1, verse = 1)
        assertNotEquals(v1.id, v2.id)
    }

    @Test
    fun `id is stable when provided explicitly`() {
        val fixedId = UUID.randomUUID()
        val verse = Verse(id = fixedId, text = "X", reference = "X 1:1", book = "X", chapter = 1, verse = 1)
        assertEquals(fixedId, verse.id)
    }
}
