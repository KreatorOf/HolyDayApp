package com.matthiascadet.holyday.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Équivalent Android de `GlassCompat.swift` : sur iOS, `.appGlassEffect` s'appuie sur le flou
 * "Liquid Glass" du système (iOS 26+). Compose ne capture pas nativement le contenu affiché sous
 * une surface — un vrai flou d'arrière-plan demanderait une dépendance tierce (ex. Haze). L'
 * équivalent idiomatique Material 3 est une surface tonale translucide avec ombre douce et liseré
 * subtil : même sensation de légèreté/profondeur, sans dépendance supplémentaire ni rendu fragile.
 */
fun Modifier.softSurface(
  shape: Shape = RoundedCornerShape(28.dp),
  tint: Color? = null,
  borderColor: Color? = null,
  borderAlpha: Float = 0.14f,
  elevation: Dp = 6.dp,
): Modifier = composed {
  val resolvedTint = tint ?: MaterialTheme.colorScheme.surface
  val resolvedBorder = borderColor ?: MaterialTheme.colorScheme.onSurface.copy(alpha = borderAlpha)
  this
    .shadow(elevation, shape, ambientColor = Color.Black.copy(alpha = 0.10f), spotColor = Color.Black.copy(alpha = 0.10f))
    .clip(shape)
    .background(resolvedTint.copy(alpha = 0.94f), shape)
    .border(1.dp, resolvedBorder, shape)
}

/** Carte tonale réutilisable : remplace le trio `clip + background + border` dupliqué à travers l'app. */
@Composable
fun SoftCard(
  modifier: Modifier = Modifier,
  shape: Shape = MaterialTheme.shapes.large,
  tint: Color? = null,
  borderColor: Color? = null,
  content: @Composable ColumnScope.() -> Unit,
) {
  Column(
    modifier = modifier.fillMaxWidth().softSurface(shape = shape, tint = tint, borderColor = borderColor),
    content = content,
  )
}

/** Champ de texte sans liseré dur : fond tonal, coins généreux — le pendant Material du composeur en verre iOS. */
@Composable
fun softTextFieldColors() = TextFieldDefaults.colors(
  focusedIndicatorColor = Color.Transparent,
  unfocusedIndicatorColor = Color.Transparent,
  disabledIndicatorColor = Color.Transparent,
  errorIndicatorColor = Color.Transparent,
  focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
  unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
  disabledContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh.copy(alpha = 0.6f),
)
