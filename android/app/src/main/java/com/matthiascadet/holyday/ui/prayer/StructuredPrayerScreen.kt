package com.matthiascadet.holyday.ui.prayer

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
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.db.AppDatabase
import com.matthiascadet.holyday.data.model.Verse
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.matthiascadet.holyday.ui.theme.softSurface
import com.matthiascadet.holyday.viewmodel.PrayerGuideViewModel

/** Équivalent de `StructuredPrayerSheet` iOS : parcours ACTS en 4 étapes. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StructuredPrayerScreen(verse: Verse?, accent: Color, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val viewModel: PrayerGuideViewModel = viewModel()
    val expandedStepId by viewModel.expandedStepId.collectAsState()
    val completedSteps by viewModel.completedSteps.collectAsState()
    val prayerTexts by viewModel.prayerTexts.collectAsState()
    val reflectionQuestions by viewModel.reflectionQuestions.collectAsState()

    val intentionsDao = remember(context) { AppDatabase.getInstance(context).prayerIntentionDao() }
    val activeIntentions by intentionsDao.observeAll().collectAsState(initial = emptyList())
    val activeIntentionTexts = activeIntentions.filter { !it.isAnswered }.map { it.text }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.prayer_structured_title), color = AppTheme.colors.textPrimary) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.common_back))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            AppBackground()
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                verse?.let {
                    VerseRecall(it, accent, modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp))
                }

                viewModel.prayerSteps.forEach { step ->
                    val isSupplication = step.colorName == "supplicationGreen"
                    PrayerStepCard(
                        step = step,
                        isExpanded = expandedStepId == step.id,
                        isCompleted = completedSteps.contains(step.id),
                        prayerText = prayerTexts[step.id].orEmpty(),
                        onPrayerTextChange = { viewModel.setPrayerText(step, it) },
                        reflectionQuestions = reflectionQuestions[step.id].orEmpty(),
                        intentions = if (isSupplication) activeIntentionTexts else emptyList(),
                        onTap = { viewModel.toggleStep(step) },
                        onPray = {
                            viewModel.save(context, step, context.getString(step.titleRes))
                        },
                    )
                }

                if (viewModel.isAllCompleted()) {
                    CompletionCard(onDismiss)
                }
            }
        }
    }
}

@Composable
private fun CompletionCard(onDismiss: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(4.dp)
            .softSurface(shape = RoundedCornerShape(20.dp), tint = AppTheme.colors.cardSurface),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = AppTheme.colors.adorationPurple, modifier = Modifier.padding(top = 20.dp))
        Text(
            stringResource(R.string.content_completion_title),
            style = MaterialTheme.typography.titleLarge,
            color = AppTheme.colors.textPrimary,
        )
        Text(
            stringResource(R.string.content_completion_subtitle),
            style = MaterialTheme.typography.bodyMedium,
            color = AppTheme.colors.textSecondary,
        )
        Button(
            onClick = onDismiss,
            colors = ButtonDefaults.buttonColors(containerColor = AppTheme.colors.adorationPurple.copy(alpha = 0.12f), contentColor = AppTheme.colors.adorationPurple),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 20.dp),
        ) {
            Text(stringResource(R.string.prayer_structured_finish))
        }
    }
}
