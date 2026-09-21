package com.matthiascadet.holyday.ui.prayer

import androidx.compose.animation.core.tween
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.db.SavedVerseEntity
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Verset révélé mot par mot, puis référence affichée une fois le verset complet. Équivalent de
 * `EmotionVerseView`.
 */
@Composable
fun EmotionVerse(verse: Verse, accent: Color, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).savedVerseDao() }
    val savedVerses by dao.observeAll().collectAsState(initial = emptyList())
    val saved = savedVerses.firstOrNull { it.text == verse.text && it.reference == verse.reference }
    val scope = rememberCoroutineScope()
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
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = verse.reference,
                style = androidx.compose.material3.MaterialTheme.typography.labelLarge,
                color = referenceAlpha,
                textAlign = TextAlign.Center,
            )
            IconButton(
                enabled = isComplete,
                onClick = {
                    scope.launch {
                        if (saved == null) dao.upsert(SavedVerseEntity(text = verse.text, reference = verse.reference))
                        else dao.delete(saved)
                    }
                },
                modifier = Modifier.size(48.dp),
            ) {
                Icon(
                    if (saved == null) Icons.Outlined.BookmarkBorder else Icons.Filled.Bookmark,
                    contentDescription = stringResource(if (saved == null) R.string.saved_verses_add else R.string.saved_verses_remove),
                    tint = referenceAlpha,
                )
            }
        }
    }
}
