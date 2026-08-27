package com.matthiascadet.holyday.ui.support

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.SupporterTier
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.delay

/**
 * Équivalent de `DonationThankYouView` iOS : célébration plein écran, fermeture automatique
 * après 3 secondes. Simplifié : pas d'effet de particules scintillantes (`SparksView`).
 */
@Composable
fun DonationThankYouScreen(tier: SupporterTier? = null, onDismiss: () -> Unit) {
    LaunchedEffect(Unit) {
        delay(3000)
        onDismiss()
    }

    val color = tier?.color() ?: AppTheme.colors.thanksgivingGold

    Box(Modifier.fillMaxSize()) {
        AppBackground()
        Column(
            modifier = Modifier.fillMaxSize().padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = androidx.compose.foundation.layout.Arrangement.Center,
        ) {
            Box(
                modifier = Modifier.size(112.dp).background(color.copy(alpha = 0.15f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(tier?.icon ?: Icons.Filled.Favorite, contentDescription = null, tint = color, modifier = Modifier.size(46.dp))
            }
            androidx.compose.foundation.layout.Spacer(Modifier.padding(top = 18.dp))
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
                androidx.compose.foundation.layout.Spacer(Modifier.padding(top = 6.dp))
                SupporterBadge(it, size = SupporterBadgeSize.LARGE)
            }
        }
    }
}
