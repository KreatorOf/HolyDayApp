package com.matthiascadet.holyday.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Valeurs exactes extraites des fichiers colorset de HolyDay/Assets.xcassets (composants sRGB
 * iOS), converties en ARGB. Conserver la parité visuelle avec l'app iOS : ne pas retoucher ces
 * teintes sans mettre aussi à jour les colorset iOS correspondants.
 */
object BrandColors {
    val adaptiveOrangeLight = Color(0xFFA04800)
    val adaptiveOrangeDark = Color(0xFFFF9500)

    val adorationPurpleLight = Color(0xFF7339BC)
    val adorationPurpleDark = Color(0xFF8C59D9)

    val confessionBlueLight = Color(0xFF2461B8)
    val confessionBlueDark = Color(0xFF4C99F2)

    val thanksgivingGoldLight = Color(0xFFE6A81A)
    val thanksgivingGoldDark = Color(0xFFFFD140)

    val supplicationGreenLight = Color(0xFF257A53)
    val supplicationGreenDark = Color(0xFF4CCC99)

    val backgroundPrimaryLight = Color(0xFFFDF8E6)
    val backgroundPrimaryDark = Color(0xFF1F1039)

    val cardSurfaceLight = Color(0xFFFFFDF6)
    val cardSurfaceDark = Color(0xFF2A194A)

    val cardStrokeLight = Color(0x1A000000)
    val cardStrokeDark = Color(0x14FFFFFF)

    val cardFillLight = Color(0x0A000000)
    val cardFillDark = Color(0x0DFFFFFF)

    val dividerLight = Color(0x14000000)
    val dividerDark = Color(0x12FFFFFF)

    val buttonFillSubtleLight = Color(0x12000000)
    val buttonFillSubtleDark = Color(0x14FFFFFF)

    val premiumShadowLight = Color(0x14000000)
    val premiumShadowDark = Color(0x4C000000)

    // Teintes pastel des émotions (identiques quel que soit le thème, cf. Emotion.pastel iOS).
    val emotionJoy = Color(0xFFFFD140)
    val emotionPeace = Color(0xFF66CC94)
    val emotionGratitude = Color(0xFFFC946B)
    val emotionSadness = Color(0xFF66A3ED)
    val emotionFear = Color(0xFFB28FF5)
    val emotionFatigue = Color(0xFF7585D1)
    val emotionAnger = Color(0xFFED6B66)
    val emotionHope = Color(0xFF42C2BA)
}
