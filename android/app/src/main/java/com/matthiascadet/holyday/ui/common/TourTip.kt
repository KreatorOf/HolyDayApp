package com.matthiascadet.holyday.ui.common

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.FormatListBulleted
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupProperties
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.service.TourService
import com.matthiascadet.holyday.ui.theme.AppTheme

enum class TourTipPlacement { TOP_END, CENTER, BOTTOM }

/** Coach-mark non modal, positionné près de la commande qu'il explique. */
@Composable
fun TourTip(
    step: TourService.Step,
    placement: TourTipPlacement = TourTipPlacement.CENTER,
    onDismiss: () -> Unit,
) {
    val content = when (step) {
        TourService.Step.EMOTIONS -> TipContent(R.string.tour_emotions_title, R.string.tour_emotions_message, Icons.Filled.Favorite, AppTheme.colors.adaptiveOrange)
        TourService.Step.PRAY -> TipContent(R.string.tour_pray_title, R.string.tour_pray_message, Icons.Filled.AutoAwesome, AppTheme.colors.adorationPurple)
        TourService.Step.INTENTIONS -> TipContent(R.string.tour_intentions_title, R.string.tour_intentions_message, Icons.AutoMirrored.Filled.FormatListBulleted, AppTheme.colors.supplicationGreen)
        TourService.Step.JOURNAL -> TipContent(R.string.tour_journal_title, R.string.tour_journal_message, Icons.AutoMirrored.Filled.MenuBook, AppTheme.colors.confessionBlue)
        TourService.Step.COMPLETE -> return
    }
    val alignment = when (placement) {
        TourTipPlacement.TOP_END -> Alignment.TopEnd
        TourTipPlacement.CENTER -> Alignment.Center
        TourTipPlacement.BOTTOM -> Alignment.BottomCenter
    }
    val density = LocalDensity.current
    val offset = with(density) {
        when (placement) {
            TourTipPlacement.TOP_END -> IntOffset((-12).dp.roundToPx(), 72.dp.roundToPx())
            TourTipPlacement.CENTER -> IntOffset(0, 48.dp.roundToPx())
            TourTipPlacement.BOTTOM -> IntOffset(0, (-132).dp.roundToPx())
        }
    }
    val actionContentColor = if (content.accent.luminance() > 0.3f) Color.Black else Color.White

    Popup(
        alignment = alignment,
        offset = offset,
        properties = PopupProperties(focusable = false, clippingEnabled = true),
    ) {
        Surface(
            modifier = Modifier.width(320.dp).padding(12.dp),
            shape = MaterialTheme.shapes.large,
            color = AppTheme.colors.cardSurface,
            tonalElevation = 8.dp,
            shadowElevation = 8.dp,
        ) {
            Column(
                modifier = Modifier.padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier.size(42.dp).background(content.accent.copy(alpha = 0.16f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { Icon(content.icon, contentDescription = null, tint = content.accent) }
                    Spacer(Modifier.width(12.dp))
                    Text(stringResource(content.titleRes), style = MaterialTheme.typography.titleMedium, color = AppTheme.colors.textPrimary)
                }
                Text(stringResource(content.messageRes), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textSecondary)
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = content.accent, contentColor = actionContentColor),
                ) { Text(stringResource(R.string.common_continue)) }
            }
        }
    }
}

private data class TipContent(
    @StringRes val titleRes: Int,
    @StringRes val messageRes: Int,
    val icon: ImageVector,
    val accent: Color,
)
