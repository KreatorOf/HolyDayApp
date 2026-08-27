package com.matthiascadet.holyday.data.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.ui.theme.AppTheme
import java.util.UUID

/** Une des 4 étapes de la prière guidée ACTS (Adoration, Confession, Actions de grâce, Supplication). */
data class PrayerStep(
    val id: UUID = UUID.randomUUID(),
    val titleRes: Int,
    val descriptionRes: Int,
    val icon: ImageVector,
    val colorName: String,
    val order: Int,
) {
    @Composable
    fun color(): Color = AppTheme.colorFor(colorName)

    companion object {
        val defaultSteps: List<PrayerStep> = listOf(
            PrayerStep(
                titleRes = R.string.step_adoration_title,
                descriptionRes = R.string.step_adoration_description,
                icon = Icons.Filled.AutoAwesome,
                colorName = "adorationPurple",
                order = 1,
            ),
            PrayerStep(
                titleRes = R.string.step_confession_title,
                descriptionRes = R.string.step_confession_description,
                icon = Icons.Filled.Favorite,
                colorName = "confessionBlue",
                order = 2,
            ),
            PrayerStep(
                titleRes = R.string.step_thanksgiving_title,
                descriptionRes = R.string.step_thanksgiving_description,
                icon = Icons.Filled.Star,
                colorName = "thanksgivingGold",
                order = 3,
            ),
            PrayerStep(
                titleRes = R.string.step_supplication_title,
                descriptionRes = R.string.step_supplication_description,
                icon = Icons.AutoMirrored.Filled.Chat,
                colorName = "supplicationGreen",
                order = 4,
            ),
        )
    }
}
