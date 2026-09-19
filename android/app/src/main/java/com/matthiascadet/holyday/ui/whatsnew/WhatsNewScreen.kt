package com.matthiascadet.holyday.ui.whatsnew

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.ReleaseNote
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Feuille Material 3 des nouveautés, sans dépendance réseau. */
@Composable
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
fun WhatsNewScreen(releases: List<ReleaseNote>, onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = AppTheme.colors.backgroundPrimary,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().fillMaxHeight(0.9f).padding(horizontal = 28.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                Text(
                    stringResource(R.string.whatsnew_title),
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = AppTheme.colors.textPrimary,
                    modifier = Modifier.weight(1f),
                )
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.common_close), tint = AppTheme.colors.textPrimary)
                }
            }
            Column(
                modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(top = 12.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp),
            ) {
                if (releases.size == 1) {
                    Text(stringResource(R.string.whatsnew_version, releases.first().version), color = AppTheme.colors.textSecondary)
                }
                releases.forEach { release ->
                    Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                        if (releases.size > 1) {
                            Text(
                                stringResource(R.string.whatsnew_version, release.version),
                                style = MaterialTheme.typography.labelLarge,
                                color = AppTheme.colors.textTertiary,
                            )
                        }
                        release.items.forEach { item -> ReleaseNoteRow(item) }
                    }
                }
                Spacer(Modifier.height(16.dp))
            }
            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppTheme.colors.adorationPurple),
                shape = RoundedCornerShape(16.dp),
            ) {
                Text(stringResource(R.string.whatsnew_continue), modifier = Modifier.padding(vertical = 6.dp), fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun ReleaseNoteRow(item: ReleaseNote.Item) {
    val color = AppTheme.colorFor(item.colorName)
    Row(verticalAlignment = Alignment.Top) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier.size(44.dp).background(color.copy(alpha = 0.12f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(iconFor(item.icon), contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
            }
            Box(Modifier.padding(top = 6.dp).width(2.dp).height(30.dp).background(color.copy(alpha = 0.16f)))
        }
        Spacer(Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(stringResource(item.titleRes), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = AppTheme.colors.textPrimary)
            Text(stringResource(item.bodyRes), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textSecondary)
        }
    }
}

private fun iconFor(icon: ReleaseNote.Icon): ImageVector = when (icon) {
    ReleaseNote.Icon.BOOK -> Icons.AutoMirrored.Filled.MenuBook
    ReleaseNote.Icon.DESCRIPTION -> Icons.Filled.Description
    ReleaseNote.Icon.LANGUAGE -> Icons.Filled.Language
    ReleaseNote.Icon.WIDGETS -> Icons.Filled.Widgets
    ReleaseNote.Icon.NOTIFICATIONS -> Icons.Filled.Notifications
    ReleaseNote.Icon.QUICK_PRAY -> Icons.Filled.PlayArrow
}
