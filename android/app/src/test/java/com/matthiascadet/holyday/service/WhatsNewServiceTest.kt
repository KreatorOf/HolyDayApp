package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.model.ReleaseNote
import com.matthiascadet.holyday.testutil.FakeSharedPreferences
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Miroir des invariants couverts par `WhatsNewServiceTests.swift`. */
class WhatsNewServiceTest {
    private fun note(version: String) = ReleaseNote(version, emptyList())

    private fun service(
        prefs: FakeSharedPreferences = FakeSharedPreferences(),
        version: String = "1.1",
        catalog: List<String> = listOf("1.1"),
    ) = WhatsNewService(prefs, currentVersion = { version }, catalog = catalog.map(::note))

    @Test
    fun `a fresh installation shows no release notes after onboarding`() {
        val service = service()
        service.markSeen()
        service.evaluate()
        assertNull(service.pending.value)
    }

    @Test
    fun `no recorded version shows only the installed version`() {
        val service = service(catalog = listOf("1.0.1", "1.1"))
        service.evaluate()
        assertEquals(listOf("1.1"), service.pending.value?.map { it.version })
    }

    @Test
    fun `upgrade catches skipped versions newest first`() {
        val prefs = FakeSharedPreferences()
        prefs.edit().putString(WhatsNewService.LAST_SEEN_KEY, "1.0.1").apply()
        val service = service(prefs, version = "1.3", catalog = listOf("1.0.1", "1.1", "1.2", "1.3"))
        service.evaluate()
        assertEquals(listOf("1.3", "1.2", "1.1"), service.pending.value?.map { it.version })
    }

    @Test
    fun `a version without notes advances the marker`() {
        val prefs = FakeSharedPreferences()
        prefs.edit().putString(WhatsNewService.LAST_SEEN_KEY, "1.1").apply()
        val service = service(prefs, version = "1.2", catalog = listOf("1.1"))
        service.evaluate()
        assertNull(service.pending.value)
        assertEquals("1.2", prefs.getString(WhatsNewService.LAST_SEEN_KEY, null))
    }

    @Test
    fun `reset replays the current version`() {
        val service = service()
        service.markSeen()
        service.reset()
        service.evaluate()
        assertEquals(listOf("1.1"), service.pending.value?.map { it.version })
    }

    @Test
    fun `versions are compared numerically`() {
        assertTrue(WhatsNewService.isVersionNewer("1.10", "1.9"))
        assertTrue(WhatsNewService.isVersionNewer("2.0", "1.99"))
        assertFalse(WhatsNewService.isVersionNewer("1.0", "1.0"))
        assertFalse(WhatsNewService.isVersionNewer("1.0", "1.0.1"))
    }
}
