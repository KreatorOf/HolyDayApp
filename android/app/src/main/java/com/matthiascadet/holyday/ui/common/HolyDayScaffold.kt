package com.matthiascadet.holyday.ui.common

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.ui.theme.AppTheme

/** Structure visuelle commune des écrans secondaires HolyDay. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HolyDayScaffold(
    title: String,
    onBack: (() -> Unit)? = null,
    actions: @Composable () -> Unit = {},
    bottomBar: @Composable () -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    Box(Modifier.fillMaxSize()) {
        AppBackground()
        Scaffold(
            containerColor = Color.Transparent,
            topBar = {
                TopAppBar(
                    title = { Text(title, color = AppTheme.colors.textPrimary) },
                    navigationIcon = {
                        onBack?.let {
                            IconButton(onClick = it) {
                                Icon(
                                    Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = stringResource(R.string.common_back),
                                    tint = AppTheme.colors.textPrimary,
                                )
                            }
                        }
                    },
                    actions = { actions() },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent),
                )
            },
            bottomBar = bottomBar,
            content = content,
        )
    }
}
