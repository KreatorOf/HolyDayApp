package com.matthiascadet.holyday.data.prefs

import android.content.Context
import android.content.SharedPreferences

/**
 * Équivalent de `UserDefaults.standard` côté iOS. Les widgets tournant dans le même process
 * que l'app sur Android (contrairement à l'extension WidgetKit iOS), un simple
 * `SharedPreferences` suffit à la fois pour l'état interne de l'app et pour le pont avec les
 * widgets Glance — pas besoin d'équivalent "App Group".
 */
object AppPreferences {
    private const val PREFS_NAME = "holyday_prefs"

    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        if (::prefs.isInitialized) return
        prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    val raw: SharedPreferences get() = prefs
}
