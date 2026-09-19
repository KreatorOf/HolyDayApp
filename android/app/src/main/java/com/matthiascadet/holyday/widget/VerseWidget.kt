package com.matthiascadet.holyday.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.DpSize
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.LocalSize
import androidx.glance.appwidget.SizeMode
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
    override val sizeMode = SizeMode.Responsive(
        setOf(DpSize(110.dp, 110.dp), DpSize(220.dp, 110.dp), DpSize(220.dp, 220.dp)),
    )

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
    val size = LocalSize.current
    val compact = size.width < 180.dp || size.height < 140.dp
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(BrandColors.backgroundPrimaryDark))
            .padding(if (compact) 12.dp else 18.dp)
            .clickable(actionStartActivity<MainActivity>()),
    ) {
        val kickerStyle = TextStyle(
            color = ColorProvider(BrandColors.adorationPurpleDark),
            fontSize = if (compact) 11.sp else 12.sp,
            fontWeight = FontWeight.Medium,
        )
        val quoteStyle = TextStyle(
            color = ColorProvider(androidx.compose.ui.graphics.Color.White),
            fontSize = if (compact) 13.sp else 16.sp,
        )
        val referenceStyle = TextStyle(
            color = ColorProvider(androidx.compose.ui.graphics.Color.White.copy(alpha = 0.7f)),
            fontSize = if (compact) 10.sp else 12.sp,
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
