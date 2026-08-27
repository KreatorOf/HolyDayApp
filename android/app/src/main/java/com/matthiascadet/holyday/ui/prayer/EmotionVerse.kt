package com.matthiascadet.holyday.ui.prayer

import androidx.compose.animation.core.tween
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.delay

/**
 * Verset révélé mot par mot, puis référence affichée une fois le verset complet. Équivalent de
 * `EmotionVerseView`.
 */
@Composable
fun EmotionVerse(verse: Verse, accent: Color, modifier: Modifier = Modifier) {
    val tokens = remember(verse.id) { listOf("«") + verse.text.split(" ") + listOf("»") }
    var revealedCount by remember(verse.id) { mutableIntStateOf(0) }

    LaunchedEffect(verse.id) {
        revealedCount = 0
        for (index in 1..tokens.size) {
            delay(110)
            revealedCount = index
        }
    }

    val isComplete = revealedCount >= tokens.size
    val referenceAlpha by animateColorAsState(
        targetValue = if (isComplete) accent else accent.copy(alpha = 0f),
        animationSpec = tween(400),
        label = "referenceAlpha",
    )

    Column(
        modifier = modifier.padding(horizontal = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text(
            text = tokens.take(revealedCount).joinToString(" "),
            fontStyle = FontStyle.Italic,
            style = androidx.compose.material3.MaterialTheme.typography.titleMedium,
            color = AppTheme.colors.textPrimary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            text = verse.reference,
            style = androidx.compose.material3.MaterialTheme.typography.labelLarge,
            color = referenceAlpha,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
