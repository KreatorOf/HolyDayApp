package com.matthiascadet.holyday.ui.support

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.service.SupportPromptService
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Équivalent de `SupportPromptView` iOS. */
@Composable
fun SupportPromptScreen(onSupport: () -> Unit, onLater: () -> Unit, onDontAskAgain: () -> Unit) {
    Box(Modifier.fillMaxSize()) {
        AppBackground()
        Column(
            modifier = Modifier.fillMaxSize().padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Box(
                    modifier = Modifier.size(96.dp).background(AppTheme.colors.adorationPurple.copy(alpha = 0.12f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = AppTheme.colors.adorationPurple, modifier = Modifier.size(38.dp))
                }
                Text(
                    stringResource(R.string.support_prompt_title),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    fontStyle = FontStyle.Italic,
                    color = AppTheme.colors.textPrimary,
                    textAlign = TextAlign.Center,
                )
                Text(
                    stringResource(R.string.support_prompt_message),
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppTheme.colors.textSecondary,
                    textAlign = TextAlign.Center,
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.fillMaxWidth()) {
                Button(
                    onClick = onSupport,
                    colors = ButtonDefaults.buttonColors(containerColor = AppTheme.colors.adorationPurple),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) { Text(stringResource(R.string.support_prompt_cta)) }

                TextButton(onClick = onLater) { Text(stringResource(R.string.support_prompt_later), color = AppTheme.colors.textSecondary) }

                Text(
                    stringResource(R.string.support_prompt_never),
                    style = MaterialTheme.typography.labelSmall,
                    color = AppTheme.colors.textTertiary,
                    textDecoration = TextDecoration.Underline,
                    modifier = Modifier.padding(top = 2.dp, bottom = 4.dp).clickable(onClick = onDontAskAgain),
                )
            }
        }
    }
}
