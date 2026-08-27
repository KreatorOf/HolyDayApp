package com.matthiascadet.holyday.ui.support

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope

import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.model.SupporterTier
import com.matthiascadet.holyday.service.TipService
import com.matthiascadet.holyday.ui.common.AppBackground
import com.matthiascadet.holyday.ui.theme.AppTheme
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesTransactionException
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore
import kotlinx.coroutines.launch

/** Équivalent de `HolyDayPaywallView` iOS. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallScreen(onDismiss: () -> Unit, onDonated: (SupporterTier) -> Unit = {}) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val offering by TipService.tipsOffering.collectAsState()
    var isPurchasing by remember { mutableStateOf(false) }
    var showError by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { TipService.refreshCustomerInfo() }

    val ranked = remember(offering) { (offering?.availablePackages ?: emptyList()).sortedBy { it.product.price.amountMicros } }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.paywall_header_title), color = AppTheme.colors.textPrimary) },
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
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                Box(modifier = Modifier.size(72.dp).clip(CircleShape).background(AppTheme.colors.adorationPurple.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = AppTheme.colors.adorationPurple)
                }
                Text(stringResource(R.string.paywall_header_title), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, fontStyle = FontStyle.Italic, color = AppTheme.colors.textPrimary)
                Text(stringResource(R.string.paywall_header_subtitle), style = MaterialTheme.typography.bodyMedium, color = AppTheme.colors.textSecondary)

                ranked.forEachIndexed { index, pkg ->
                    val tier = SupporterTier.entries.getOrNull(index) ?: return@forEachIndexed
                    TipRow(pkg, tier) {
                        scope.launch {
                            isPurchasing = true
                            try {
                                val activity = context as? Activity
                                if (activity != null) {
                                    Purchases.sharedInstance.awaitPurchase(PurchaseParams.Builder(activity, pkg).build())
                                    TipService.recordPurchase(tier)
                                    TipService.refreshCustomerInfo()
                                    onDonated(tier)
                                }
                            } catch (e: PurchasesTransactionException) {
                                if (!e.userCancelled) showError = true
                            } catch (e: Exception) {
                                showError = true
                            } finally {
                                isPurchasing = false
                            }
                        }
                    }
                }

                TextButton(onClick = {
                    scope.launch {
                        isPurchasing = true
                        try {
                            val info = Purchases.sharedInstance.awaitRestore()
                            TipService.applyCustomerInfo(info)
                            TipService.refreshCustomerInfo()
                            onDismiss()
                        } catch (e: Exception) {
                            showError = true
                        } finally {
                            isPurchasing = false
                        }
                    }
                }) { Text(stringResource(R.string.paywall_restore), color = AppTheme.colors.textTertiary) }

                Text(stringResource(R.string.paywall_legal_footer), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textTertiary)
            }

            if (isPurchasing) {
                Box(Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.25f)), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = AppTheme.colors.adorationPurple)
                }
            }
        }
    }

    if (showError) {
        AlertDialog(
            onDismissRequest = { showError = false },
            title = { Text(stringResource(R.string.paywall_error_title)) },
            text = { Text(stringResource(R.string.paywall_error_message)) },
            confirmButton = { TextButton(onClick = { showError = false }) { Text(stringResource(R.string.common_cancel)) } },
        )
    }
}

@Composable
private fun TipRow(pkg: Package, tier: SupporterTier, onClick: () -> Unit) {
    val color = tier.color()
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(AppTheme.colors.cardSurface)
            .border(1.dp, color.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
            .clickable(onClick = onClick)
            .padding(14.dp),
    ) {
        Box(modifier = Modifier.size(44.dp).clip(CircleShape).background(color.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
            Text(tier.emoji)
        }
        Column(modifier = Modifier.weight(1f).padding(start = 14.dp)) {
            Text(stringResource(tier.titleRes), color = AppTheme.colors.textPrimary, fontWeight = FontWeight.SemiBold)
            Text(stringResource(tier.phraseRes), style = MaterialTheme.typography.labelSmall, color = AppTheme.colors.textSecondary)
        }
        Text(pkg.product.price.formatted, color = color, fontWeight = FontWeight.SemiBold)
    }
}
