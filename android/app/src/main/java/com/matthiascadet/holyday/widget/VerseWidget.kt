package com.matthiascadet.holyday.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.matthiascadet.holyday.MainActivity
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.service.WidgetSyncService
import com.matthiascadet.holyday.ui.theme.BrandColors

/** Équivalent de `VerseWidget` iOS : affiche le dernier verset reçu dans l'app. */
class VerseWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val text = WidgetSyncService.lastVerseText()
        val reference = WidgetSyncService.lastVerseReference()
        provideContent {
            VerseWidgetContent(context, text, reference)
        }
    }
}

@Composable
private fun VerseWidgetContent(context: Context, text: String?, reference: String?) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(BrandColors.backgroundPrimaryDark))
            .padding(12.dp)
            .clickable(actionStartActivity<MainActivity>()),
    ) {
        val kickerStyle = TextStyle(
            color = ColorProvider(BrandColors.adorationPurpleDark),
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
        )
        val quoteStyle = TextStyle(
            color = ColorProvider(androidx.compose.ui.graphics.Color.White),
            fontSize = 14.sp,
        )
        val referenceStyle = TextStyle(
            color = ColorProvider(androidx.compose.ui.graphics.Color.White.copy(alpha = 0.7f)),
            fontSize = 11.sp,
        )

        Text(context.getString(R.string.widget_verse_kicker), style = kickerStyle)
        if (text.isNullOrBlank()) {
            Text(context.getString(R.string.widget_verse_empty), style = quoteStyle)
        } else {
            Text(context.getString(R.string.widget_verse_quote, text), style = quoteStyle)
            reference?.let { Text(it, style = referenceStyle) }
        }
    }
}

class VerseWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = VerseWidget()
}
