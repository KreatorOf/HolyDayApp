package com.matthiascadet.holyday.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.ui.common.HolyDayScaffold
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Équivalent de `LegalNoticeView` iOS. */
@Composable
fun LegalNoticeScreen(onDismiss: () -> Unit) {
    HolyDayScaffold(title = stringResource(R.string.legal_nav_title), onBack = onDismiss) { padding ->
        Box(Modifier.fillMaxWidth().padding(padding), contentAlignment = androidx.compose.ui.Alignment.TopCenter) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .widthIn(max = 720.dp)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                LegalSection(stringResource(R.string.legal_section_publisher), stringResource(R.string.legal_section_publisher_content))
                LegalSection(stringResource(R.string.legal_section_data), stringResource(R.string.legal_section_data_content))
                LegalSection(stringResource(R.string.legal_section_notifications), stringResource(R.string.legal_section_notifications_content))
                LegalSection(stringResource(R.string.legal_section_biblical), stringResource(R.string.legal_section_biblical_content))
                LegalSection(stringResource(R.string.legal_section_ip), stringResource(R.string.legal_section_ip_content))
                LegalSection(stringResource(R.string.legal_section_liability), stringResource(R.string.legal_section_liability_content))
                LegalSection(stringResource(R.string.legal_section_contact), "matthias.cadet25@gmail.com")
                Text(stringResource(R.string.legal_last_update), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary)
            }
        }
    }
}

@Composable
private fun LegalSection(title: String, content: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AppTheme.colors.cardSurface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = AppTheme.colors.textPrimary)
        Text(
            content,
            style = MaterialTheme.typography.bodyMedium,
            color = AppTheme.colors.textSecondary,
            lineHeight = MaterialTheme.typography.bodyMedium.lineHeight * 1.25f,
        )
    }
}
