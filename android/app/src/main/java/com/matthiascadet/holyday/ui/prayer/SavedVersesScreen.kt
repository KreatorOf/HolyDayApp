package com.matthiascadet.holyday.ui.prayer

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.ui.common.HolyDayScaffold
import com.matthiascadet.holyday.ui.theme.AppTheme
import kotlinx.coroutines.launch

@Composable
fun SavedVersesScreen(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val dao = remember(context) { AppDatabase.getInstance(context).savedVerseDao() }
    val verses by dao.observeAll().collectAsState(initial = emptyList())
    val scope = rememberCoroutineScope()

    HolyDayScaffold(title = stringResource(R.string.saved_verses_title), onBack = onDismiss) { padding ->
        if (verses.isEmpty()) {
            Column(
                Modifier.fillMaxSize().padding(padding).padding(32.dp),
                verticalArrangement = Arrangement.Center,
            ) {
                Text(stringResource(R.string.saved_verses_empty_title), style = MaterialTheme.typography.titleLarge)
                Text(
                    stringResource(R.string.saved_verses_empty_message),
                    color = AppTheme.colors.textSecondary,
                    modifier = Modifier.padding(top = 8.dp),
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(verses, key = { it.id }) { verse ->
                    Card {
                        Column(Modifier.padding(18.dp)) {
                            Text("“${verse.text}”", fontStyle = FontStyle.Italic, color = AppTheme.colors.textPrimary)
                            Text(
                                verse.reference,
                                color = AppTheme.colors.adorationPurple,
                                style = MaterialTheme.typography.labelLarge,
                                modifier = Modifier.padding(top = 8.dp),
                            )
                            OutlinedTextField(
                                value = verse.note,
                                onValueChange = { note -> scope.launch { dao.update(verse.copy(note = note)) } },
                                label = { Text(stringResource(R.string.saved_verses_note_placeholder)) },
                                trailingIcon = {
                                    IconButton(onClick = { scope.launch { dao.delete(verse) } }) {
                                        Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.common_delete))
                                    }
                                },
                                modifier = Modifier.fillMaxWidth().padding(top = 10.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}
