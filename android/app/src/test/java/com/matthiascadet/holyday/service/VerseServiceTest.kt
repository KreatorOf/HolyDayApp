package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.VerseCorpus
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Équivalent de `VerseServiceTests.swift`. */
class VerseServiceTest {

    @Test
    fun `verse for emotion returns non-empty text for all emotions`() {
        for (emotion in Emotion.entries) {
            val verse = VerseService.verse(emotion)
            assertFalse("Texte vide pour ${emotion.id}", verse.text.isEmpty())
        }
    }

    @Test
    fun `verse for emotion has valid reference for all emotions`() {
        for (emotion in Emotion.entries) {
            val verse = VerseService.verse(emotion)
            assertFalse("Référence vide pour ${emotion.id}", verse.reference.isEmpty())
            assertFalse("Livre vide pour ${emotion.id}", verse.book.isEmpty())
            assertTrue(verse.chapter > 0)
            assertTrue(verse.verse > 0)
        }
    }

    @Test
    fun `corpus covers every emotion with at least two verses`() {
        for (emotion in Emotion.entries) {
            val pool = VerseCorpus.all.filter { it.emotionTags.contains(emotion.id) }
            assertTrue("Le thème ${emotion.id} a moins de deux versets", pool.size >= 2)
        }
    }

    @Test
    fun `verse for emotion avoids immediate repetition`() {
        for (emotion in Emotion.entries) {
            val v1 = VerseService.verse(emotion)
            val v2 = VerseService.verse(emotion)
            assertNotEquals("Répétition immédiate pour ${emotion.id}", v1.reference, v2.reference)
        }
    }

    @Test
    fun `verse for emotion survives deck exhaustion`() {
        for (emotion in Emotion.entries) {
            repeat(VerseCorpus.all.size * 3) {
                val verse = VerseService.verse(emotion)
                assertFalse(verse.text.isEmpty())
            }
        }
    }
}
