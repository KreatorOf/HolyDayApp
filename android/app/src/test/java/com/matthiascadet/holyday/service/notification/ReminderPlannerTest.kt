package com.matthiascadet.holyday.service.notification

import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.data.model.VerseCorpus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

/** Équivalent de `ReminderPlannerTests.swift` : mêmes scénarios, mêmes dates. */
class ReminderPlannerTest {

    private fun day(dayOfMonth: Int): LocalDate = LocalDate.of(2026, 9, dayOfMonth)

    @Test
    fun `prayed earlier that day skips reminder`() {
        assertNull(ReminderPlanner.kindFor(day(16), ReminderContext(lastPrayerDate = day(16))))
    }

    @Test
    fun `prayed yesterday keeps reminder`() {
        assertEquals(
            ReminderKind.Question,
            ReminderPlanner.kindFor(day(16), ReminderContext(lastPrayerDate = day(15))),
        )
    }

    @Test
    fun `emotion follow up offers verse of that theme for two days`() {
        val context = ReminderContext(lastEmotion = Emotion.SADNESS, lastEmotionDate = day(16))
        for (d in listOf(17, 18)) {
            val kind = ReminderPlanner.kindFor(day(d), context)
            assertTrue("verset attendu le $d", kind is ReminderKind.Verse)
            val index = (kind as ReminderKind.Verse).corpusIndex
            assertTrue(VerseCorpus.all[index].emotionTags.contains("sadness"))
        }
        assertEquals(ReminderKind.Question, ReminderPlanner.kindFor(day(19), context))
    }

    @Test
    fun `emotion follow up wins over sunday intentions`() {
        val context = ReminderContext(
            lastEmotion = Emotion.FEAR,
            lastEmotionDate = day(19),
            oldestOpenIntentionDate = day(1),
        )
        assertTrue(ReminderPlanner.kindFor(day(20), context) is ReminderKind.Verse)
    }

    @Test
    fun `verse index is deterministic per day`() {
        val first = ReminderPlanner.verseIndex(Emotion.HOPE, day(18))
        assertNotNull(first)
        assertEquals(first, ReminderPlanner.verseIndex(Emotion.HOPE, day(18)))
    }

    @Test
    fun `old open intention invites on sunday only`() {
        val context = ReminderContext(oldestOpenIntentionDate = day(1))
        assertEquals(ReminderKind.Intentions, ReminderPlanner.kindFor(day(20), context))
        assertEquals(ReminderKind.Question, ReminderPlanner.kindFor(day(21), context))
    }

    @Test
    fun `recent intention does not invite yet`() {
        val context = ReminderContext(oldestOpenIntentionDate = day(14))
        assertEquals(ReminderKind.Question, ReminderPlanner.kindFor(day(20), context))
    }

    @Test
    fun `no intention never invites`() {
        assertEquals(ReminderKind.Question, ReminderPlanner.kindFor(day(20), ReminderContext()))
    }
}
