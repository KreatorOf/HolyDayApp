package com.matthiascadet.holyday.viewmodel

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** Équivalent de `PrayerGuideViewModelTests.swift`. */
class PrayerGuideViewModelTest {

    private lateinit var sut: PrayerGuideViewModel

    @Before
    fun setUp() {
        sut = PrayerGuideViewModel()
    }

    // MARK: - État initial

    @Test
    fun `init loads four steps`() {
        assertEquals(4, sut.prayerSteps.size)
    }

    @Test
    fun `init progress is zero`() {
        assertEquals(0.0, sut.progressPercentage(), 0.001)
    }

    @Test
    fun `init isAllCompleted is false`() {
        assertFalse(sut.isAllCompleted())
    }

    @Test
    fun `init no expanded step`() {
        assertNull(sut.expandedStepId.value)
    }

    // MARK: - Progression

    @Test
    fun `markCompleted adds to completed set`() {
        val step = sut.prayerSteps[0]
        sut.markCompleted(step)
        assertTrue(sut.completedSteps.value.contains(step.id))
    }

    @Test
    fun `markCompleted one step progress is 25 percent`() {
        sut.markCompleted(sut.prayerSteps[0])
        assertEquals(0.25, sut.progressPercentage(), 0.001)
    }

    @Test
    fun `markCompleted two steps progress is 50 percent`() {
        sut.markCompleted(sut.prayerSteps[0])
        sut.markCompleted(sut.prayerSteps[1])
        assertEquals(0.50, sut.progressPercentage(), 0.001)
    }

    @Test
    fun `markCompleted all steps isAllCompleted is true`() {
        sut.prayerSteps.forEach { sut.markCompleted(it) }
        assertTrue(sut.isAllCompleted())
        assertEquals(1.0, sut.progressPercentage(), 0.001)
    }

    @Test
    fun `isCompleted returns false before mark`() {
        assertFalse(sut.isCompleted(sut.prayerSteps[0]))
    }

    @Test
    fun `isCompleted returns true after mark`() {
        val step = sut.prayerSteps[0]
        sut.markCompleted(step)
        assertTrue(sut.isCompleted(step))
    }

    // MARK: - Expansion

    @Test
    fun `toggleStep expands step`() {
        val step = sut.prayerSteps[0]
        sut.toggleStep(step)
        assertTrue(sut.isExpanded(step))
    }

    @Test
    fun `toggleStep collapses if already expanded`() {
        val step = sut.prayerSteps[0]
        sut.toggleStep(step)
        sut.toggleStep(step)
        assertFalse(sut.isExpanded(step))
    }

    @Test
    fun `toggleStep only one step expanded at a time`() {
        val s1 = sut.prayerSteps[0]
        val s2 = sut.prayerSteps[1]
        sut.toggleStep(s1)
        sut.toggleStep(s2)
        assertFalse(sut.isExpanded(s1))
        assertTrue(sut.isExpanded(s2))
    }

    @Test
    fun `markCompleted collapses expanded step`() {
        val step = sut.prayerSteps[0]
        sut.toggleStep(step)
        sut.markCompleted(step)
        assertNull(sut.expandedStepId.value)
    }

    // MARK: - Reset

    @Test
    fun `resetProgress clears completed steps`() {
        sut.prayerSteps.forEach { sut.markCompleted(it) }
        sut.resetProgress()
        assertTrue(sut.completedSteps.value.isEmpty())
    }

    @Test
    fun `resetProgress clears prayer texts`() {
        sut.setPrayerText(sut.prayerSteps[0], "texte de prière")
        sut.resetProgress()
        assertTrue(sut.prayerTexts.value.isEmpty())
    }

    @Test
    fun `resetProgress resets progress`() {
        sut.prayerSteps.forEach { sut.markCompleted(it) }
        sut.resetProgress()
        assertEquals(0.0, sut.progressPercentage(), 0.001)
        assertFalse(sut.isAllCompleted())
    }

    @Test
    fun `resetProgress closes expanded step`() {
        sut.toggleStep(sut.prayerSteps[0])
        sut.resetProgress()
        assertNull(sut.expandedStepId.value)
    }
}
