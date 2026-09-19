package com.matthiascadet.holyday.service

import android.content.SharedPreferences
import com.matthiascadet.holyday.data.model.ReleaseNote
import com.matthiascadet.holyday.data.model.ReleaseNotesCatalog
import com.matthiascadet.holyday.data.prefs.AppPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Décide quelles notes de version annoncer après une mise à jour.
 *
 * L'onboarding appelle [markSeen] avant d'ouvrir l'écran principal : une installation neuve ne
 * voit donc jamais des nouveautés qu'elle découvre pour la première fois. L'absence de repère
 * correspond ainsi sans ambiguïté à une mise à jour depuis un binaire plus ancien.
 */
class WhatsNewService(
    private val preferences: SharedPreferences = AppPreferences.raw,
    private val currentVersion: () -> String,
    private val catalog: List<ReleaseNote> = ReleaseNotesCatalog.all,
) {
    private val _pending = MutableStateFlow<List<ReleaseNote>?>(null)
    val pending: StateFlow<List<ReleaseNote>?> = _pending.asStateFlow()

    fun evaluate() {
        val version = currentVersion()
        val lastSeen = preferences.getString(LAST_SEEN_KEY, null)
        val releases = releasesNewerThan(lastSeen, version)
        if (releases.isEmpty()) {
            markSeen()
        } else {
            _pending.value = releases
        }
    }

    fun markSeen() {
        preferences.edit().putString(LAST_SEEN_KEY, currentVersion()).apply()
        _pending.value = null
    }

    /** Réservé au menu développeur, comme sur iOS. */
    fun reset() {
        preferences.edit().remove(LAST_SEEN_KEY).apply()
        _pending.value = null
    }

    private fun releasesNewerThan(lastSeen: String?, version: String): List<ReleaseNote> =
        if (lastSeen == null) {
            catalog.filter { it.version == version }
        } else {
            catalog
                .filter { isVersionNewer(it.version, lastSeen) && !isVersionNewer(it.version, version) }
                .sortedWith { first, second -> if (isVersionNewer(first.version, second.version)) -1 else 1 }
        }

    companion object {
        const val LAST_SEEN_KEY = "holyday.whatsNew.lastSeenVersion"

        val shared: WhatsNewService by lazy {
            WhatsNewService(currentVersion = { com.matthiascadet.holyday.BuildConfig.VERSION_NAME.substringBefore('-') })
        }

        /** Comparaison numérique : 1.10 est bien postérieure à 1.9. */
        fun isVersionNewer(lhs: String, rhs: String): Boolean {
            val left = lhs.split('.').map { it.toIntOrNull() ?: 0 }
            val right = rhs.split('.').map { it.toIntOrNull() ?: 0 }
            val size = maxOf(left.size, right.size)
            return (0 until size).firstOrNull { index ->
                (left.getOrElse(index) { 0 }) != (right.getOrElse(index) { 0 })
            }?.let { index -> left.getOrElse(index) { 0 } > right.getOrElse(index) { 0 } } ?: false
        }
    }
}
