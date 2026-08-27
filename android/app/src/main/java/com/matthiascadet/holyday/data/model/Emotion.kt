package com.matthiascadet.holyday.data.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.VolunteerActivism
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.BrandColors

/**
 * État intérieur que l'utilisateur déclare avant de prier.
 * `id` est stable et non localisé : c'est lui qui est persisté sur `PrayerEntry`
 * (équivalent de la `rawValue` de l'enum Swift `Emotion`).
 */
enum class Emotion(val id: String, val titleRes: Int, val icon: ImageVector, val colorName: String, val pastel: Color) {
    JOY("joy", R.string.emotion_joy, Icons.Filled.WbSunny, "thanksgivingGold", BrandColors.emotionJoy),
    PEACE("peace", R.string.emotion_peace, Icons.Filled.Spa, "confessionBlue", BrandColors.emotionPeace),
    GRATITUDE("gratitude", R.string.emotion_gratitude, Icons.Filled.VolunteerActivism, "thanksgivingGold", BrandColors.emotionGratitude),
    SADNESS("sadness", R.string.emotion_sadness, Icons.Filled.Umbrella, "confessionBlue", BrandColors.emotionSadness),
    FEAR("fear", R.string.emotion_fear, Icons.Filled.Air, "adorationPurple", BrandColors.emotionFear),
    FATIGUE("fatigue", R.string.emotion_fatigue, Icons.Filled.Bedtime, "supplicationGreen", BrandColors.emotionFatigue),
    ANGER("anger", R.string.emotion_anger, Icons.Filled.LocalFireDepartment, "adaptiveOrange", BrandColors.emotionAnger),
    HOPE("hope", R.string.emotion_hope, Icons.Filled.WbTwilight, "supplicationGreen", BrandColors.emotionHope);

    @Composable
    fun color(): Color = AppTheme.colorFor(colorName)

    companion object {
        fun fromId(id: String?): Emotion? = id?.let { value -> entries.find { it.id == value } }
    }
}
