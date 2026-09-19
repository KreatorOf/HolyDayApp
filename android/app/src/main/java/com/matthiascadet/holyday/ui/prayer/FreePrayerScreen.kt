package com.matthiascadet.holyday.ui.prayer

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.common.HolyDayScaffold
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.softTextFieldColors

/** Équivalent de `FreePrayerSheet` iOS. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FreePrayerScreen(verse: Verse?, accent: Color, onSave: (String) -> Unit, onDismiss: () -> Unit) {
    var text by remember { mutableStateOf("") }
    val canSave = text.trim().isNotEmpty()

    HolyDayScaffold(
        title = stringResource(R.string.prayer_free_title),
        onBack = onDismiss,
        bottomBar = {
            Button(
                onClick = { onSave(text); onDismiss() },
                enabled = canSave,
                colors = ButtonDefaults.buttonColors(containerColor = accent),
                elevation = ButtonDefaults.buttonElevation(defaultElevation = 2.dp, pressedElevation = 0.dp),
                shape = MaterialTheme.shapes.large,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 12.dp)
                    .navigationBarsPadding()
                    .imePadding(),
            ) {
                Icon(Icons.Filled.AutoAwesome, contentDescription = null)
                Text(stringResource(R.string.prayer_free_amen), modifier = Modifier.padding(start = 8.dp))
            }
        },
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(padding).padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            verse?.let { VerseRecall(it, accent, modifier = Modifier.padding(horizontal = 8.dp)) }

            TextField(
                value = text,
                onValueChange = { text = it },
                placeholder = { Text(stringResource(R.string.prayer_free_placeholder)) },
                shape = MaterialTheme.shapes.large,
                colors = softTextFieldColors(),
                textStyle = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.fillMaxWidth().heightIn(min = 220.dp),
            )
        }
    }
}
