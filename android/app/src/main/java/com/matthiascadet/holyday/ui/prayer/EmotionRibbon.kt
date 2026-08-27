package com.matthiascadet.holyday.ui.prayer

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.clickable
import com.matthiascadet.holyday.data.model.Emotion
import com.matthiascadet.holyday.ui.theme.AppTheme

/**
 * Deux rangées d'émotions qui défilent en boucle continue en sens opposés. Tap pour sélectionner.
 * Équivalent simplifié de `EmotionRibbonView` (pas de repli séparé "réduire les animations" —
 * Android expose ce réglage système différemment ; le défilement reste ambiant et non bloquant).
 */
@Composable
fun EmotionRibbon(onSelect: (Emotion) -> Unit, modifier: Modifier = Modifier) {
    val rows = remember { Emotion.entries.shuffled().let { it.take(it.size / 2) to it.drop(it.size / 2) } }
    Box(modifier = modifier.height(112.dp)) {
        Box(
            Modifier
                .padding(vertical = 4.dp)
                .wrapContentSize(Alignment.TopStart),
        ) {
            androidx.compose.foundation.layout.Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                MarqueeRow(rows.first, leftward = true, speedDpPerSec = 26f, onSelect = onSelect)
                MarqueeRow(rows.second, leftward = false, speedDpPerSec = 33f, onSelect = onSelect)
            }
        }
    }
}

// Défilement piloté image par image (plutôt qu'un `tween` fixe recalculé sur la largeur mesurée) :
// le décalage avance d'une distance exacte à chaque frame, ce qui élimine le micro-à-coup de
// redémarrage du `tween` précédent et garde une vitesse parfaitement constante et fluide.
@Composable
private fun MarqueeRow(
    emotions: List<Emotion>,
    leftward: Boolean,
    speedDpPerSec: Float,
    onSelect: (Emotion) -> Unit,
) {
    var contentWidthPx by remember { mutableFloatStateOf(0f) }
    var traveledPx by remember { mutableFloatStateOf(0f) }
    val density = androidx.compose.ui.platform.LocalDensity.current
    val speedPxPerSec = with(density) { speedDpPerSec.dp.toPx() }
    // Distance réelle entre le début d'une copie et le début de la suivante : la largeur mesurée
    // d'une copie SEULE, plus l'espace que l'arrangement extérieur place entre deux copies. Oublier
    // ce dernier décalait le point de rebouclage et créait un saut visible à chaque boucle.
    val copyGapPx = with(density) { 12.dp.toPx() }

    LaunchedEffect(speedPxPerSec) {
        var lastFrameNanos = -1L
        while (true) {
            withFrameNanos { frameNanos ->
                if (lastFrameNanos >= 0 && contentWidthPx > 0f) {
                    val deltaSeconds = (frameNanos - lastFrameNanos) / 1_000_000_000f
                    val next = traveledPx + speedPxPerSec * deltaSeconds
                    traveledPx = if (next >= contentWidthPx) next - contentWidthPx else next
                }
                lastFrameNanos = frameNanos
            }
        }
    }

    Box(
        Modifier
            .height(48.dp)
            .wrapContentSize(Alignment.CenterStart, unbounded = true),
    ) {
        Row(
            // Lecture de l'état DANS le lambda de graphicsLayer (et non dans le corps du
            // composable) : Compose met alors à jour la translation à chaque frame sans jamais
            // recomposer la rangée de bulles — c'était la cause des saccades précédentes.
            modifier = Modifier.graphicsLayer {
                translationX = if (leftward) -traveledPx else traveledPx - contentWidthPx
            },
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            repeat(3) { copyIndex ->
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = if (copyIndex == 0) Modifier.onGloballyPositioned {
                        if (contentWidthPx == 0f) contentWidthPx = it.size.width.toFloat() + copyGapPx
                    } else Modifier,
                ) {
                    emotions.forEach { emotion -> EmotionBubble(emotion, onSelect) }
                }
            }
        }
    }
}

@Composable
private fun EmotionBubble(emotion: Emotion, onSelect: (Emotion) -> Unit) {
    val colors = AppTheme.colors
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
        modifier = Modifier
            .clip(CircleShape)
            .background(emotion.pastel.copy(alpha = 0.20f))
            .clickable { onSelect(emotion) }
            .padding(horizontal = 16.dp, vertical = 12.dp),
    ) {
        Icon(emotion.icon, contentDescription = null, tint = emotion.pastel, modifier = Modifier.width(16.dp))
        Text(stringResource(emotion.titleRes), color = colors.textPrimary)
    }
}
