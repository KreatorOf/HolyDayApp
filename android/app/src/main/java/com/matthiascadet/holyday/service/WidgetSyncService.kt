package com.matthiascadet.holyday.service

import android.content.Context
import androidx.glance.appwidget.updateAll
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.widget.PrayNowWidget
import com.matthiascadet.holyday.widget.VerseWidget
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Pont app -> widgets. Équivalent de `SharedStore` + `WidgetSyncService` côté iOS, simplifié :
 * les widgets Glance tournent dans le même process que l'app sur Android, donc un
 * `SharedPreferences` classique suffit (pas d'App Group à répliquer).
 */
object WidgetSyncService {
    private const val LAST_PRAYER_DATE_KEY = "holyday.widget.lastPrayerDate"
    private const val LAST_VERSE_TEXT_KEY = "holyday.widget.lastVerseText"
    private const val LAST_VERSE_REFERENCE_KEY = "holyday.widget.lastVerseReference"
    private const val LAST_VERSE_EMOTION_KEY = "holyday.widget.lastVerseEmotion"

    private lateinit var appContext: Context

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    fun setLastPrayerDate(millis: Long?) {
        val editor = AppPreferences.raw.edit()
        if (millis == null) editor.remove(LAST_PRAYER_DATE_KEY) else editor.putLong(LAST_PRAYER_DATE_KEY, millis)
        editor.apply()
        sync()
    }

    fun updateLastVerse(text: String, reference: String, emotionId: String?) {
        AppPreferences.raw.edit()
            .putString(LAST_VERSE_TEXT_KEY, text)
            .putString(LAST_VERSE_REFERENCE_KEY, reference)
            .putString(LAST_VERSE_EMOTION_KEY, emotionId)
            .apply()
        sync()
    }

    fun lastPrayerDateMillis(): Long? =
        AppPreferences.raw.getLong(LAST_PRAYER_DATE_KEY, -1L).takeIf { it >= 0 }

    fun lastVerseText(): String? = AppPreferences.raw.getString(LAST_VERSE_TEXT_KEY, null)
    fun lastVerseReference(): String? = AppPreferences.raw.getString(LAST_VERSE_REFERENCE_KEY, null)
    fun lastVerseEmotionId(): String? = AppPreferences.raw.getString(LAST_VERSE_EMOTION_KEY, null)

    /** Recharge les timelines des deux widgets (équivalent `WidgetCenter.reloadAllTimelines()`). */
    fun sync() {
        if (!::appContext.isInitialized) return
        CoroutineScope(Dispatchers.Default).launch {
            PrayNowWidget().updateAll(appContext)
            VerseWidget().updateAll(appContext)
        }
    }
}
