package com.matthiascadet.holyday.service

import com.matthiascadet.holyday.data.model.SupporterTier
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.ui.theme.RevenueCatConfig
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Équivalent de `TipService` iOS : dons consommables via RevenueCat, badge dérivé du palier
 * le plus récent (jamais du plus élevé jamais atteint — voir `applyCustomerInfo`).
 */
object TipService {
    private const val HAS_TIPPED_KEY = "holyday.hasTipped"
    private const val HIGHEST_TIP_INDEX_KEY = "holyday.highestTipIndex"

    private val _hasTipped = MutableStateFlow(false)
    val hasTipped: StateFlow<Boolean> = _hasTipped.asStateFlow()

    private val _tipsOffering = MutableStateFlow<Offering?>(null)
    val tipsOffering: StateFlow<Offering?> = _tipsOffering.asStateFlow()

    // Stocké en index+1 : 0 = "jamais acheté" (SharedPreferences renvoie 0 pour une clé absente).
    private var tipTierIndexStored: Int = 0

    private var tierByProductId: Map<String, SupporterTier> = emptyMap()

    val supporterTier: SupporterTier?
        get() {
            if (!_hasTipped.value) return null
            return SupporterTier.entries.find { it.rank == tipTierIndexStored - 1 }
        }

    fun init() {
        val prefs = AppPreferences.raw
        _hasTipped.value = prefs.getBoolean(HAS_TIPPED_KEY, false)
        tipTierIndexStored = prefs.getInt(HIGHEST_TIP_INDEX_KEY, 0)
        CoroutineScope(Dispatchers.IO).launch { refreshCustomerInfo() }
    }

    suspend fun refreshCustomerInfo() {
        val offerings = runCatching { Purchases.sharedInstance.awaitOfferings() }.getOrNull()
        _tipsOffering.value = offerings?.getOffering(RevenueCatConfig.OFFERING_ID)
        rebuildTierMap()

        val info = runCatching { Purchases.sharedInstance.awaitCustomerInfo() }.getOrNull()
        if (info != null) applyCustomerInfo(info)
    }

    private fun rebuildTierMap() {
        val ranked = (_tipsOffering.value?.availablePackages ?: emptyList())
            .sortedBy { it.product.price.amountMicros }
        val map = mutableMapOf<String, SupporterTier>()
        for ((index, pkg) in ranked.withIndex()) {
            val tier = SupporterTier.entries.find { it.rank == index } ?: break
            map[pkg.product.id] = tier
        }
        tierByProductId = map
    }

    fun tier(for_: String): SupporterTier? = tierByProductId[for_] ?: SupporterTier.forProductIdentifier(for_)

    /**
     * Enregistre directement le palier acheté. Les dons sont des produits consommables et,
     * en mode utilisateur anonyme, n'apparaissent plus dans CustomerInfo après l'achat — le
     * badge est donc persisté localement depuis le palier connu au moment de l'achat.
     */
    fun recordPurchase(tier: SupporterTier) {
        setHasTipped(true)
        setTipTierIndexStored(tier.rank + 1)
    }

    fun debugSetSupporter(enabled: Boolean) {
        setHasTipped(enabled)
        setTipTierIndexStored(if (enabled) 1 else 0)
    }

    /**
     * Purement ADDITIF : CustomerInfo ne sert qu'à (ré)confirmer le badge, jamais à l'effacer.
     * Pour des consommables anonymes, un CustomerInfo vide est l'état normal (pas un
     * remboursement) — l'effacer figerait le badge à "jamais visible" dès le 1er lancement.
     */
    fun applyCustomerInfo(info: CustomerInfo) {
        val entitlementActive = info.entitlements[RevenueCatConfig.ENTITLEMENT_ID]?.isActive == true
        val transactions = info.nonSubscriptionTransactions
        val hasTransactions = transactions.isNotEmpty()

        if (!entitlementActive && !hasTransactions) return
        setHasTipped(true)
        if (hasTransactions) {
            updateTier(transactions)
        } else if (tipTierIndexStored == 0) {
            setTipTierIndexStored(1)
        }
    }

    /**
     * Le badge reflète le don le PLUS RÉCENT (pas le palier le plus élevé jamais atteint) : un
     * don élevé ponctuel ne doit pas figer le badge sur ce palier indéfiniment.
     */
    private fun updateTier(transactions: List<com.revenuecat.purchases.models.Transaction>) {
        val latestTier = transactions.maxByOrNull { it.purchaseDate.time }
            ?.let { tier(it.productIdentifier) }
        setTipTierIndexStored((latestTier?.rank ?: 0) + 1)
    }

    private fun setHasTipped(value: Boolean) {
        _hasTipped.value = value
        AppPreferences.raw.edit().putBoolean(HAS_TIPPED_KEY, value).apply()
    }

    private fun setTipTierIndexStored(value: Int) {
        tipTierIndexStored = value
        AppPreferences.raw.edit().putInt(HIGHEST_TIP_INDEX_KEY, value).apply()
    }
}
