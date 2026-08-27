package com.matthiascadet.holyday.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Équivalent de `LegalNoticeView` iOS. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LegalNoticeScreen(onDismiss: () -> Unit) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.legal_nav_title), color = AppTheme.colors.textPrimary) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.common_close)) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            AppBackground()
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
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
        Text(content, style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textSecondary)
    }
}
