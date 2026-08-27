package com.matthiascadet.holyday.data.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.ui.theme.AppTheme

enum class SupporterTier(
    val rank: Int,
    val titleRes: Int,
    val badgeNameRes: Int,
    val emoji: String,
    val phraseRes: Int,
    val icon: ImageVector,
) {
    AMI(0, R.string.tier_ami, R.string.badge_name_ami, "❤️", R.string.paywall_tip_ami_phrase, Icons.Filled.Favorite),
    GENEREUX(1, R.string.tier_genereux, R.string.badge_name_genereux, "⭐️", R.string.paywall_tip_genereux_phrase, Icons.Filled.Star),
    BIENFAITEUR(2, R.string.tier_bienfaiteur, R.string.badge_name_bienfaiteur, "✨", R.string.paywall_tip_bienfaiteur_phrase, Icons.Filled.AutoAwesome);

    @Composable
    fun color(): Color = when (this) {
        AMI -> AppTheme.colors.thanksgivingGold
        GENEREUX -> AppTheme.colors.confessionBlue
        BIENFAITEUR -> AppTheme.colors.adorationPurple
    }

    companion object {
        fun forProductIdentifier(productIdentifier: String): SupporterTier? = when {
            productIdentifier.contains("tip_large") -> BIENFAITEUR
            productIdentifier.contains("tip_medium") -> GENEREUX
            productIdentifier.contains("tip_small") -> AMI
            else -> null
        }
    }
}
