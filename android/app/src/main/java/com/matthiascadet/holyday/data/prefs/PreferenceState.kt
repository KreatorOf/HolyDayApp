package com.matthiascadet.holyday.data.prefs

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

/** Lit une préférence texte et se recompose quand elle change (équivalent léger de `@AppStorage`). */
@Composable
fun rememberStringPreference(key: String, default: String = ""): State<String> {
    val state = remember { mutableStateOf(AppPreferences.raw.getString(key, default) ?: default) }
    DisposableEffect(key) {
        val listener = android.content.SharedPreferences.OnSharedPreferenceChangeListener { prefs, changedKey ->
            if (changedKey == key) state.value = prefs.getString(key, default) ?: default
        }
        AppPreferences.raw.registerOnSharedPreferenceChangeListener(listener)
        onDispose { AppPreferences.raw.unregisterOnSharedPreferenceChangeListener(listener) }
    }
    return state
}

@Composable
fun rememberBooleanPreference(key: String, default: Boolean = false): State<Boolean> {
    val state = remember { mutableStateOf(AppPreferences.raw.getBoolean(key, default)) }
    DisposableEffect(key) {
        val listener = android.content.SharedPreferences.OnSharedPreferenceChangeListener { prefs, changedKey ->
            if (changedKey == key) state.value = prefs.getBoolean(key, default)
        }
        AppPreferences.raw.registerOnSharedPreferenceChangeListener(listener)
        onDispose { AppPreferences.raw.unregisterOnSharedPreferenceChangeListener(listener) }
    }
    return state
}
