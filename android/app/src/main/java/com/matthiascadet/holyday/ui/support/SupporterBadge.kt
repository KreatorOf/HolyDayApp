package com.matthiascadet.holyday.ui.support

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.data.model.SupporterTier

enum class SupporterBadgeSize { SMALL, LARGE }
enum class SupporterBadgeStyle { FULL, ICON_ONLY }

/** Équivalent de `SupporterBadge` iOS. */
@Composable
fun SupporterBadge(
    tier: SupporterTier,
    size: SupporterBadgeSize = SupporterBadgeSize.SMALL,
    style: SupporterBadgeStyle = SupporterBadgeStyle.FULL,
) {
    val color = tier.color()
    val hPadding = if (size == SupporterBadgeSize.SMALL) 8.dp else 14.dp
    val vPadding = if (size == SupporterBadgeSize.SMALL) 4.dp else 8.dp

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .background(color.copy(alpha = 0.12f), CircleShape)
            .padding(horizontal = if (style == SupporterBadgeStyle.ICON_ONLY) vPadding else hPadding, vertical = vPadding),
    ) {
        Icon(tier.icon, contentDescription = stringResource(tier.badgeNameRes), tint = color, modifier = Modifier.padding(end = if (style == SupporterBadgeStyle.FULL) 5.dp else 0.dp))
        if (style == SupporterBadgeStyle.FULL) {
            Text(stringResource(tier.badgeNameRes), color = color, style = if (size == SupporterBadgeSize.SMALL) MaterialTheme.typography.labelSmall else MaterialTheme.typography.labelLarge)
        }
    }
}
