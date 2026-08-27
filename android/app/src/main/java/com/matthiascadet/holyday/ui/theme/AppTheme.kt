package com.matthiascadet.holyday.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** Équivalent des couleurs de marque `AppTheme` (iOS) — une valeur résolue par apparence. */
data class AppColors(
    val adorationPurple: Color,
    val confessionBlue: Color,
    val thanksgivingGold: Color,
    val supplicationGreen: Color,
    val adaptiveOrange: Color,
    val backgroundPrimary: Color,
    val cardSurface: Color,
    val cardStroke: Color,
    val cardFill: Color,
    val divider: Color,
    val buttonFillSubtle: Color,
    val premiumShadow: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
)

private fun lightAppColors() = AppColors(
    adorationPurple = BrandColors.adorationPurpleLight,
    confessionBlue = BrandColors.confessionBlueLight,
    thanksgivingGold = BrandColors.thanksgivingGoldLight,
    supplicationGreen = BrandColors.supplicationGreenLight,
    adaptiveOrange = BrandColors.adaptiveOrangeLight,
    backgroundPrimary = BrandColors.backgroundPrimaryLight,
    cardSurface = BrandColors.cardSurfaceLight,
    cardStroke = BrandColors.cardStrokeLight,
    cardFill = BrandColors.cardFillLight,
    divider = BrandColors.dividerLight,
    buttonFillSubtle = BrandColors.buttonFillSubtleLight,
    premiumShadow = BrandColors.premiumShadowLight,
    textPrimary = Color.Black.copy(alpha = 0.92f),
    textSecondary = Color.Black.copy(alpha = 0.60f),
    textTertiary = Color.Black.copy(alpha = 0.30f),
)

private fun darkAppColors() = AppColors(
    adorationPurple = BrandColors.adorationPurpleDark,
    confessionBlue = BrandColors.confessionBlueDark,
    thanksgivingGold = BrandColors.thanksgivingGoldDark,
    supplicationGreen = BrandColors.supplicationGreenDark,
    adaptiveOrange = BrandColors.adaptiveOrangeDark,
    backgroundPrimary = BrandColors.backgroundPrimaryDark,
    cardSurface = BrandColors.cardSurfaceDark,
    cardStroke = BrandColors.cardStrokeDark,
    cardFill = BrandColors.cardFillDark,
    divider = BrandColors.dividerDark,
    buttonFillSubtle = BrandColors.buttonFillSubtleDark,
    premiumShadow = BrandColors.premiumShadowDark,
    textPrimary = Color.White.copy(alpha = 0.95f),
    textSecondary = Color.White.copy(alpha = 0.65f),
    textTertiary = Color.White.copy(alpha = 0.35f),
)

private val LocalAppColors = staticCompositionLocalOf { lightAppColors() }

// Titres et branding en serif (équivalent du `design: .serif` iOS) : le corps de texte reste en
// police système par défaut, seuls les niveaux "éditoriaux" (titres d'écran, wordmark, question du
// jour) adoptent la serif, pour garder le ton chaleureux sans alourdir le reste de l'UI.
private val brandFontFamily = FontFamily.Serif

private val AppTypography = Typography().let { base ->
  base.copy(
    displaySmall = base.displaySmall.copy(fontFamily = brandFontFamily),
    headlineLarge = base.headlineLarge.copy(fontFamily = brandFontFamily, fontWeight = FontWeight.SemiBold),
    headlineMedium = base.headlineMedium.copy(fontFamily = brandFontFamily, fontWeight = FontWeight.SemiBold),
    headlineSmall = base.headlineSmall.copy(fontFamily = brandFontFamily, fontWeight = FontWeight.SemiBold),
    titleLarge = base.titleLarge.copy(fontFamily = brandFontFamily, fontWeight = FontWeight.Bold),
  )
}

// Échelle de formes "M3 Expressive" : coins plus généreux que les valeurs Material par défaut,
// pour l'aspect doux et moderne recherché sur les surfaces (cartes, boutons, champs, menus).
private val AppShapes = Shapes(
  extraSmall = RoundedCornerShape(12.dp),
  small = RoundedCornerShape(16.dp),
  medium = RoundedCornerShape(20.dp),
  large = RoundedCornerShape(28.dp),
  extraLarge = RoundedCornerShape(36.dp),
)

/** Point d'accès équivalent à `AppTheme.xxx` côté iOS, utilisable dans tout composable. */
object AppTheme {
    val colors: AppColors
        @Composable get() = LocalAppColors.current

    /** Équivalent de `AppTheme.color(for:)` : résout un nom de couleur de marque. */
    @Composable
    fun colorFor(name: String): Color = when (name) {
        "adorationPurple" -> colors.adorationPurple
        "confessionBlue" -> colors.confessionBlue
        "thanksgivingGold" -> colors.thanksgivingGold
        "supplicationGreen" -> colors.supplicationGreen
        "adaptiveOrange" -> colors.adaptiveOrange
        else -> Color.Blue
    }
}

@Composable
fun HolyDayTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val appColors = if (darkTheme) darkAppColors() else lightAppColors()
    val materialScheme = if (darkTheme) {
        darkColorScheme(
            primary = appColors.adorationPurple,
            onPrimary = Color.White,
            primaryContainer = appColors.adorationPurple.copy(alpha = 0.28f),
            onPrimaryContainer = appColors.textPrimary,
            secondaryContainer = appColors.cardFill,
            onSecondaryContainer = appColors.textPrimary,
            background = appColors.backgroundPrimary,
            onBackground = appColors.textPrimary,
            surface = appColors.cardSurface,
            onSurface = appColors.textPrimary,
            surfaceContainer = appColors.cardSurface,
            surfaceContainerHigh = appColors.cardFill,
            surfaceContainerHighest = appColors.cardStroke,
            outline = appColors.cardStroke,
            outlineVariant = appColors.divider,
        )
    } else {
        lightColorScheme(
            primary = appColors.adorationPurple,
            onPrimary = Color.White,
            primaryContainer = appColors.adorationPurple.copy(alpha = 0.16f),
            onPrimaryContainer = appColors.adorationPurple,
            secondaryContainer = appColors.cardFill,
            onSecondaryContainer = appColors.textPrimary,
            background = appColors.backgroundPrimary,
            onBackground = appColors.textPrimary,
            surface = appColors.cardSurface,
            onSurface = appColors.textPrimary,
            surfaceContainer = appColors.cardSurface,
            surfaceContainerHigh = appColors.cardFill,
            surfaceContainerHighest = appColors.cardStroke,
            outline = appColors.cardStroke,
            outlineVariant = appColors.divider,
        )
    }

    CompositionLocalProvider(LocalAppColors provides appColors) {
        MaterialTheme(
            colorScheme = materialScheme,
            typography = AppTypography,
            shapes = AppShapes,
            content = content,
        )
    }
}
