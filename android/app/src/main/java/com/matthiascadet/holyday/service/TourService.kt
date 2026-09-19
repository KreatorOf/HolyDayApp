package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.prefs.AppPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Parcours de découverte linéaire, équivalent Android des événements TipKit iOS. */
object TourService {
    private const val STEP_KEY = "holyday.tour.step"

    enum class Step { EMOTIONS, PRAY, INTENTIONS, JOURNAL, COMPLETE }

    private val _step = MutableStateFlow(loadStep())
    val step: StateFlow<Step> = _step.asStateFlow()

    /** Une fermeture suffit pour rendre l'invitation suivante éligible, comme TipKit. */
    fun dismiss(step: Step) {
        if (_step.value != step) return
        val next = Step.entries.getOrElse(step.ordinal + 1) { Step.COMPLETE }
        AppPreferences.raw.edit().putInt(STEP_KEY, next.ordinal).apply()
        _step.value = next
    }

    private fun loadStep(): Step =
        Step.entries.getOrElse(AppPreferences.raw.getInt(STEP_KEY, Step.EMOTIONS.ordinal)) { Step.EMOTIONS }
}
