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
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.WidgetSyncService
import com.matthiascadet.holyday.ui.theme.BrandColors

/** Équivalent de `PrayNowWidget` iOS : invite à prier ou confirme "prié aujourd'hui". */
class PrayNowWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prayedToday = PrayerRecordService.isPrayedToday
        val lastVerseReference = WidgetSyncService.lastVerseReference()
        provideContent {
            PrayNowWidgetContent(context, prayedToday, lastVerseReference)
        }
    }
}

@Composable
private fun PrayNowWidgetContent(context: Context, prayedToday: Boolean, lastVerseReference: String?) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(BrandColors.adorationPurpleDark))
            .padding(12.dp)
            .clickable(actionStartActivity<MainActivity>()),
    ) {
        val titleStyle = TextStyle(
            color = ColorProvider(androidx.compose.ui.graphics.Color.White),
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
        )
        val subtitleStyle = TextStyle(
            color = ColorProvider(androidx.compose.ui.graphics.Color.White.copy(alpha = 0.75f)),
            fontSize = 12.sp,
        )
        if (prayedToday) {
            Text(context.getString(R.string.widget_pray_done_title), style = titleStyle)
            Text(
                lastVerseReference ?: context.getString(R.string.widget_pray_done_subtitle),
                style = subtitleStyle,
            )
        } else {
            Text(context.getString(R.string.widget_pray_invite_title), style = titleStyle)
            Text(context.getString(R.string.widget_pray_invite_button), style = subtitleStyle)
        }
    }
}

class PrayNowWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PrayNowWidget()
}
