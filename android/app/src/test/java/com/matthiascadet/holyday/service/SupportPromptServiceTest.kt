package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.testutil.FakeSharedPreferences
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

/** Équivalent de `SupportPromptServiceTests.swift`. */
class SupportPromptServiceTest {

    private val dayMillis = 86_400_000L
    private val base = Instant.ofEpochMilli(1_000_000_000L)

    private fun service(
        prayedDays: Int,
        hasTipped: Boolean,
        now: () -> Instant = { Instant.now() },
        prefs: FakeSharedPreferences = FakeSharedPreferences(),
    ) = SupportPromptService(
        prefs = prefs,
        prayedDaysProvider = { prayedDays },
        hasTippedProvider = { hasTipped },
        now = now,
    )

    // MARK: - Seuil

    @Test
    fun `below threshold does not prompt`() {
        assertFalse(service(prayedDays = 4, hasTipped = false).shouldPrompt)
    }

    @Test
    fun `at threshold prompts on first eligibility`() {
        assertTrue(service(prayedDays = 5, hasTipped = false).shouldPrompt)
    }

    // MARK: - Donateur & opt-out

    @Test
    fun `tipper is never prompted`() {
        assertFalse(service(prayedDays = 50, hasTipped = true).shouldPrompt)
    }

    @Test
    fun `dont ask again suppresses forever`() {
        val s = service(prayedDays = 50, hasTipped = false)
        assertTrue(s.shouldPrompt)
        s.dontAskAgain()
        assertFalse(s.shouldPrompt)
    }

    // MARK: - Délai de repos (backoff)

    @Test
    fun `first cooldown blocks within 30 days then allows`() {
        var current = base
        val s = service(prayedDays = 5, hasTipped = false, now = { current })

        assertTrue(s.shouldPrompt)
        s.markShown() // timesShown = 1

        current = base.plusMillis(10 * dayMillis)
        assertFalse("Délai de 30 j non écoulé", s.shouldPrompt)

        current = base.plusMillis(31 * dayMillis)
        assertTrue("Délai de 30 j écoulé", s.shouldPrompt)
    }

    @Test
    fun `second cooldown is ninety days`() {
        var current = base
        val s = service(prayedDays = 5, hasTipped = false, now = { current })

        s.markShown() // 1
        current = base.plusMillis(31 * dayMillis)
        s.markShown() // 2 -> prochain délai = 90 j

        current = base.plusMillis((31 + 31) * dayMillis)
        assertFalse("Délai de 90 j non écoulé", s.shouldPrompt)

        current = base.plusMillis((31 + 91) * dayMillis)
        assertTrue("Délai de 90 j écoulé", s.shouldPrompt)
    }

    // MARK: - Plafond

    @Test
    fun `cap after three shows never prompts again`() {
        var current = base
        val s = service(prayedDays = 5, hasTipped = false, now = { current })

        s.markShown() // 1
        current = base.plusMillis(200 * dayMillis)
        s.markShown() // 2
        current = base.plusMillis(400 * dayMillis)
        s.markShown() // 3 (= plafond)

        current = base.plusMillis(5000 * dayMillis)
        assertFalse("Plafond de 3 sollicitations atteint", s.shouldPrompt)
    }

    // MARK: - Persistance

    @Test
    fun `state is persisted across instances`() {
        val prefs = FakeSharedPreferences()
        val first = service(prayedDays = 5, hasTipped = false, now = { base }, prefs = prefs)
        first.markShown()

        val second = service(prayedDays = 5, hasTipped = false, now = { base.plusMillis(5 * dayMillis) }, prefs = prefs)
        assertFalse("L'état doit être relu depuis le stockage partagé", second.shouldPrompt)
    }

    // MARK: - Reset

    @Test
    fun `reset restores promptability`() {
        val s = service(prayedDays = 5, hasTipped = false)
        s.dontAskAgain()
        assertFalse(s.shouldPrompt)

        s.reset()
        assertTrue("Après reset, la sollicitation est de nouveau autorisée", s.shouldPrompt)
    }
}
