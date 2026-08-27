package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.db.PrayerEntryEntity
import com.matthiascadet.holyday.data.model.PrayerStep

/**
 * Équivalent de `AIAssistantService` iOS (FoundationModels / Apple Intelligence on-device).
 *
 * Gap de parité assumé : il n'existe pas d'équivalent Android fiable et universel à
 * FoundationModels (Gemini Nano / AICore n'est disponible que sur certains appareils Pixel
 * récents, pas sur l'ensemble du parc Android). Ce service dégrade donc systématiquement vers
 * les mêmes replis que l'app iOS utilise déjà quand Apple Intelligence est indisponible : pas
 * de titre suggéré, pas de question de réflexion générée, pas de recherche sémantique. Le
 * comportement fonctionnel de l'app est identique à un iPhone non compatible Apple Intelligence
 * — documenté dans le rapport de portage, ce n'est pas un oubli.
 */
object AIAssistantService {
    val isAvailable: Boolean = false

    suspend fun generateTitle(text: String): String? = null

    suspend fun generateReflectionQuestions(
        step: PrayerStep,
        recentEntries: List<PrayerEntryEntity> = emptyList(),
    ): List<String> = emptyList()

    suspend fun searchEntries(query: String, entries: List<PrayerEntryEntity>): List<PrayerEntryEntity> = emptyList()
}
