package com.matthiascadet.holyday.ui.intentions

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Équivalent de `IntentionDetailView` iOS. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IntentionDetailScreen(intentionId: String, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).prayerIntentionDao() }
    val scope = rememberCoroutineScope()
    val intentions by dao.observeAll().collectAsState(initial = emptyList())
    val intention = intentions.find { it.id == intentionId } ?: return

    var isEditing by remember { mutableStateOf(false) }
    var draft by remember(intention.id) { mutableStateOf(intention.text) }
    val formatter = remember { DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG) }
    val zone = ZoneId.systemDefault()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                navigationIcon = {
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.common_close)) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
            )
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).padding(24.dp)) {
            Text(
                stringResource(if (intention.isAnswered) R.string.intentions_section_answered else R.string.intentions_section_active),
                color = if (intention.isAnswered) AppTheme.colors.supplicationGreen else AppTheme.colors.adorationPurple,
                style = MaterialTheme.typography.labelMedium,
            )
            androidx.compose.foundation.layout.Spacer(Modifier.height(16.dp))

            if (isEditing) {
                OutlinedTextField(value = draft, onValueChange = { draft = it }, modifier = Modifier.fillMaxWidth())
            } else {
                Text(
                    intention.text,
                    style = MaterialTheme.typography.titleMedium,
                    color = AppTheme.colors.textPrimary,
                    textDecoration = if (intention.isAnswered) TextDecoration.LineThrough else null,
                )
            }

            androidx.compose.foundation.layout.Spacer(Modifier.height(16.dp))
            Text(
                stringResource(R.string.intentions_detail_added, Instant.ofEpochMilli(intention.createdAt).atZone(zone).format(formatter)),
                style = MaterialTheme.typography.bodySmall,
                color = AppTheme.colors.textSecondary,
            )
            intention.answeredAt?.let {
                Text(
                    stringResource(R.string.intentions_detail_answered, Instant.ofEpochMilli(it).atZone(zone).format(formatter)),
                    style = MaterialTheme.typography.bodySmall,
                    color = AppTheme.colors.textSecondary,
                )
            }

            androidx.compose.foundation.layout.Spacer(Modifier.weight(1f))

            if (isEditing) {
                Button(
                    onClick = {
                        val trimmed = draft.trim()
                        if (trimmed.isNotEmpty()) scope.launch { dao.update(intention.copy(text = trimmed)) }
                        isEditing = false
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) { Text(stringResource(R.string.intentions_edit_save)) }
            } else {
                Button(
                    onClick = {
                        scope.launch {
                            if (intention.isAnswered) {
                                dao.update(intention.copy(isAnswered = false, answeredAt = null))
                            } else {
                                dao.update(intention.copy(isAnswered = true, answeredAt = System.currentTimeMillis()))
                                onDismiss()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (intention.isAnswered) AppTheme.colors.adorationPurple else AppTheme.colors.supplicationGreen,
                    ),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(stringResource(if (intention.isAnswered) R.string.intentions_action_restore else R.string.intentions_action_glory))
                }

                androidx.compose.foundation.layout.Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(onClick = { isEditing = true }, modifier = Modifier.weight(1f)) {
                        Icon(Icons.Filled.Edit, contentDescription = null)
                        Text(stringResource(R.string.intentions_action_edit), modifier = Modifier.padding(start = 8.dp))
                    }
                    OutlinedButton(
                        onClick = { scope.launch { dao.delete(intention) }; onDismiss() },
                        modifier = Modifier.weight(1f),
                    ) {
                        Icon(Icons.Filled.Delete, contentDescription = null)
                        Text(stringResource(R.string.common_delete), modifier = Modifier.padding(start = 8.dp))
                    }
                }
            }
        }
    }
}
