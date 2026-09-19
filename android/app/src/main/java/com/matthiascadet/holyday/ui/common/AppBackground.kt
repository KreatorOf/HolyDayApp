package com.matthiascadet.holyday.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.matthiascadet.holyday.ui.theme.AppTheme

/**
 * Fond global volontairement uni. La profondeur visuelle est portée par les surfaces, les ombres
 * et les accents locaux afin d'éviter toute rupture de teinte entre les zones d'un même écran.
 */
@Composable
fun AppBackground(modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxSize().background(AppTheme.colors.backgroundPrimary))
}
