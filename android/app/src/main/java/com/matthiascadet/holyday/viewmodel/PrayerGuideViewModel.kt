package com.matthiascadet.holyday.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.data.model.PrayerStep
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.WidgetSyncService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

/**
 * Équivalent de `PrayerGuideViewModel` iOS : pilote le parcours guidé ACTS. Ne détient aucune
 * référence à `Context`/Room dans son état (comme l'iOS ne détient pas de `ModelContext`) : le
 * contexte n'est requis qu'au moment de `save()`, ce qui garde la logique d'état pure et
 * testable en JVM sans dépendance Android (voir `PrayerGuideViewModelTest`).
 */
class PrayerGuideViewModel : ViewModel() {
    val prayerSteps: List<PrayerStep> = PrayerStep.defaultSteps

    private val _expandedStepId = MutableStateFlow<UUID?>(null)
    val expandedStepId: StateFlow<UUID?> = _expandedStepId.asStateFlow()

    private val _completedSteps = MutableStateFlow<Set<UUID>>(emptySet())
    val completedSteps: StateFlow<Set<UUID>> = _completedSteps.asStateFlow()

    private val _prayerTexts = MutableStateFlow<Map<UUID, String>>(emptyMap())
    val prayerTexts: StateFlow<Map<UUID, String>> = _prayerTexts.asStateFlow()

    private val _reflectionQuestions = MutableStateFlow<Map<UUID, List<String>>>(emptyMap())
    val reflectionQuestions: StateFlow<Map<UUID, List<String>>> = _reflectionQuestions.asStateFlow()

    private val stepOpenedAt = mutableMapOf<UUID, Long>()

    fun toggleStep(step: PrayerStep) {
        if (_expandedStepId.value != step.id) {
            stepOpenedAt[step.id] = System.currentTimeMillis()
        }
        _expandedStepId.value = if (_expandedStepId.value == step.id) null else step.id
    }

    fun isExpanded(step: PrayerStep): Boolean = _expandedStepId.value == step.id
    fun isCompleted(step: PrayerStep): Boolean = _completedSteps.value.contains(step.id)

    fun setPrayerText(step: PrayerStep, text: String) {
        _prayerTexts.value = _prayerTexts.value + (step.id to text)
    }

    fun setReflectionQuestions(step: PrayerStep, questions: List<String>) {
        _reflectionQuestions.value = _reflectionQuestions.value + (step.id to questions)
    }

    fun save(context: Context, step: PrayerStep, stepTitle: String) {
        val dao = AppDatabase.getInstance(context).prayerEntryDao()
        val text = _prayerTexts.value[step.id].orEmpty()
        val openedAt = stepOpenedAt[step.id]
        val durationSeconds = if (openedAt != null) (System.currentTimeMillis() - openedAt) / 1000.0 else 0.0

        viewModelScope.launch {
            dao.upsert(
                PrayerEntryEntity(
                    stepTitle = stepTitle,
                    stepIcon = stepIconKey(step),
                    stepColorName = step.colorName,
                    text = text,
                    date = System.currentTimeMillis(),
                    durationSeconds = durationSeconds,
                ),
            )
            markCompleted(step)
            if (isAllCompleted()) {
                PrayerRecordService.recordPrayer()
            }
            WidgetSyncService.sync()
        }
    }

    private fun stepIconKey(step: PrayerStep): String = when (step.order) {
        1 -> com.matthiascadet.holyday.data.db.PrayerStepIcon.ADORATION
        2 -> com.matthiascadet.holyday.data.db.PrayerStepIcon.CONFESSION
        3 -> com.matthiascadet.holyday.data.db.PrayerStepIcon.THANKSGIVING
        else -> com.matthiascadet.holyday.data.db.PrayerStepIcon.SUPPLICATION
    }

    fun markCompleted(step: PrayerStep) {
        _completedSteps.value = _completedSteps.value + step.id
        _expandedStepId.value = null
    }

    fun resetProgress() {
        _completedSteps.value = emptySet()
        _expandedStepId.value = null
        _prayerTexts.value = emptyMap()
    }

    fun progressPercentage(): Double =
        if (prayerSteps.isEmpty()) 0.0 else _completedSteps.value.size.toDouble() / prayerSteps.size

    fun isAllCompleted(): Boolean =
        prayerSteps.isNotEmpty() && _completedSteps.value.size == prayerSteps.size
}
