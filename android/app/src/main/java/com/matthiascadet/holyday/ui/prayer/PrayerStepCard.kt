package com.matthiascadet.holyday.ui.prayer

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.PrayerStep
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.softSurface
import com.matthiascadet.holyday.ui.theme.softTextFieldColors

/** Une carte d'étape ACTS repliable. Équivalent de `PrayerStepView`. */
@Composable
fun PrayerStepCard(
    step: PrayerStep,
    isExpanded: Boolean,
    isCompleted: Boolean,
    prayerText: String,
    onPrayerTextChange: (String) -> Unit,
    reflectionQuestions: List<String>,
    intentions: List<String>,
    onTap: () -> Unit,
    onPray: () -> Unit,
) {
    val stepColor = step.color()
    var showReflection by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .softSurface(
                shape = RoundedCornerShape(20.dp),
                tint = AppTheme.colors.cardSurface,
                borderColor = stepColor.copy(alpha = if (isExpanded) 0.5f else 0.2f),
            ),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().clickable { onTap() }.padding(22.dp),
        ) {
            Box(
                modifier = Modifier.size(44.dp).clip(CircleShape).background(stepColor.copy(alpha = if (isCompleted) 0.2f else 0.12f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(if (isCompleted) Icons.Filled.Check else step.icon, contentDescription = null, tint = stepColor)
            }
            Column(modifier = Modifier.padding(start = 16.dp).weight(1f)) {
                Text(
                    text = stringResource(step.titleRes),
                    style = MaterialTheme.typography.titleMedium.copy(fontSize = 19.sp, lineHeight = 24.sp),
                    fontWeight = FontWeight.SemiBold,
                    color = AppTheme.colors.textPrimary,
                    textDecoration = if (isCompleted) TextDecoration.LineThrough else null,
                )
                if (!isExpanded) {
                    Text(
                        text = stringResource(if (isCompleted) R.string.step_saved else R.string.step_tap_to_pray),
                        style = MaterialTheme.typography.labelMedium,
                        color = if (isCompleted) stepColor.copy(alpha = 0.8f) else AppTheme.colors.textTertiary,
                    )
                }
            }
            Icon(
                Icons.Filled.KeyboardArrowDown,
                contentDescription = null,
                tint = stepColor,
                modifier = Modifier.rotate(if (isExpanded) 180f else 0f),
            )
        }

        AnimatedVisibility(visible = isExpanded) {
            Column(
                modifier = Modifier.padding(horizontal = 22.dp).padding(bottom = 22.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = stringResource(step.descriptionRes),
                        style = MaterialTheme.typography.bodyLarge,
                        color = AppTheme.colors.textSecondary,
                        modifier = Modifier.weight(1f),
                    )
                    if (reflectionQuestions.isNotEmpty()) {
                        IconButton(onClick = { showReflection = !showReflection }) {
                            Icon(Icons.Filled.Lightbulb, contentDescription = stringResource(R.string.accessibility_reflection_toggle), tint = stepColor)
                        }
                    }
                }

                if (showReflection && reflectionQuestions.isNotEmpty()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(stepColor.copy(alpha = 0.06f))
                            .border(1.dp, stepColor.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                            .padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(
                            stringResource(R.string.step_reflection_title),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = AppTheme.colors.textTertiary,
                        )
                        reflectionQuestions.forEach { question ->
                            Text(
                                "• $question",
                                style = MaterialTheme.typography.bodyLarge,
                                fontStyle = FontStyle.Italic,
                                color = AppTheme.colors.textSecondary,
                            )
                        }
                    }
                }

                if (intentions.isNotEmpty()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(stepColor.copy(alpha = 0.06f))
                            .border(1.dp, stepColor.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                            .padding(14.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(
                            stringResource(R.string.step_intentions_title),
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = AppTheme.colors.textTertiary,
                        )
                        intentions.forEach { intention ->
                            Text(intention, style = MaterialTheme.typography.bodyLarge, color = AppTheme.colors.textPrimary)
                        }
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        stringResource(R.string.step_prayer_title),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = AppTheme.colors.textTertiary,
                    )
                    TextField(
                        value = prayerText,
                        onValueChange = onPrayerTextChange,
                        placeholder = { Text(stringResource(R.string.step_prayer_placeholder)) },
                        enabled = !isCompleted,
                        shape = RoundedCornerShape(18.dp),
                        colors = softTextFieldColors(),
                        modifier = Modifier.fillMaxWidth().heightIn(min = 90.dp, max = 180.dp),
                    )
                }

                if (isCompleted) {
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(stepColor.copy(alpha = 0.12f))
                            .border(1.5.dp, stepColor.copy(alpha = 0.35f), RoundedCornerShape(12.dp))
                            .padding(vertical = 14.dp),
                    ) {
                        Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = stepColor)
                        Text(
                            stringResource(R.string.step_prayed),
                            style = MaterialTheme.typography.bodyLarge,
                            color = stepColor,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(start = 10.dp),
                        )
                    }
                } else {
                    val canPray = prayerText.trim().isNotEmpty()
                    Button(
                        onClick = onPray,
                        enabled = canPray,
                        colors = ButtonDefaults.buttonColors(containerColor = stepColor),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Icon(Icons.Filled.AutoAwesome, contentDescription = null)
                        Text(
                            stringResource(R.string.prayer_free_amen),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(start = 10.dp),
                        )
                    }
                }
            }
        }
    }
}
