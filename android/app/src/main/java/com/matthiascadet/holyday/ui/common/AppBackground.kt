package com.matthiascadet.holyday.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Équivalent de `AppBackground` iOS : fond uni clair, dégradé violet profond en sombre. */
@Composable
fun AppBackground(modifier: Modifier = Modifier) {
    val colors = AppTheme.colors
    val isDark = isSystemInDarkTheme()
    val brush = if (isDark) {
        Brush.radialGradient(listOf(colors.adorationPurple.copy(alpha = 0.18f), colors.backgroundPrimary))
    } else {
        Brush.linearGradient(listOf(colors.backgroundPrimary, colors.backgroundPrimary))
    }
    androidx.compose.foundation.layout.Box(modifier = modifier.fillMaxSize().background(brush))
}
