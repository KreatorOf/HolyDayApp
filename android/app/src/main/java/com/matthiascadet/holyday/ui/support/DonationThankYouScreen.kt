package com.matthiascadet.holyday.ui.support

import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Spacer
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.SupporterTier
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.AppLinks

/**
 * Équivalent de `DonationThankYouView` iOS. La célébration reste ouverte afin que l'invitation
 * secondaire à noter l'application reste réellement accessible.
 */
@Composable
fun DonationThankYouScreen(tier: SupporterTier? = null, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val color = tier?.color() ?: AppTheme.colors.thanksgivingGold
    val celebration = rememberInfiniteTransition(label = "donationCelebration")
    val glowScale by celebration.animateFloat(
        initialValue = 0.96f,
        targetValue = 1.08f,
        animationSpec = infiniteRepeatable(tween(1300), repeatMode = RepeatMode.Reverse),
        label = "glowScale",
    )

    Box(Modifier.fillMaxSize()) {
        AppBackground()
        Column(
            modifier = Modifier.fillMaxSize().padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = androidx.compose.foundation.layout.Arrangement.Center,
        ) {
            Box(
                modifier = Modifier
                    .size(112.dp)
                    .graphicsLayer { scaleX = glowScale; scaleY = glowScale }
                    .background(color.copy(alpha = 0.15f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(tier?.icon ?: Icons.Filled.Favorite, contentDescription = null, tint = color, modifier = Modifier.size(46.dp))
            }
            Spacer(Modifier.padding(top = 18.dp))
            Text(
                stringResource(R.string.donation_thankyou_title),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                fontStyle = FontStyle.Italic,
                color = AppTheme.colors.textPrimary,
                textAlign = TextAlign.Center,
            )
            Text(
                stringResource(R.string.donation_thankyou_subtitle),
                style = MaterialTheme.typography.bodyMedium,
                color = AppTheme.colors.textSecondary,
                textAlign = TextAlign.Center,
            )
            tier?.let {
                Spacer(Modifier.padding(top = 6.dp))
                SupporterBadge(it, size = SupporterBadgeSize.LARGE)
            }
        }
        Column(
            modifier = Modifier.align(Alignment.BottomCenter).padding(horizontal = 32.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            androidx.compose.material3.Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
            ) { Text(stringResource(R.string.common_continue)) }
            Spacer(Modifier.size(14.dp))
            Text(
                stringResource(R.string.donation_thankyou_rate),
                style = MaterialTheme.typography.bodyMedium,
                color = AppTheme.colors.textSecondary,
                modifier = Modifier.clickable { AppLinks.openReview(context) }.padding(8.dp),
            )
        }
    }
}
