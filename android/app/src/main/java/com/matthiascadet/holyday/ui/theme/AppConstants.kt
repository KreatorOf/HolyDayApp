package com.matthiascadet.holyday.ui.theme

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri

/** Équivalent de `AppLinks` (HolyDay/Theme/AppConstants.swift). */
object AppLinks {
    const val PRIVACY_POLICY = "https://holyday-landing.vercel.app/privacy.html"
    const val TERMS_OF_SERVICE = "https://holyday-landing.vercel.app/terms.html"
    const val PLAY_STORE = "https://play.google.com/store/apps/details?id=com.matthiascadet.holyday"
    const val PLAY_STORE_MARKET = "market://details?id=com.matthiascadet.holyday"

    /** Ouvre le formulaire de notation Play Store avec un repli navigateur si Play Store manque. */
    fun openReview(context: Context) {
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(PLAY_STORE_MARKET)))
        } catch (_: ActivityNotFoundException) {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(PLAY_STORE)))
        }
    }
}

/**
 * Équivalent de `RevenueCatConfig` (HolyDay/Theme/AppConstants.swift). La clé API Android est
 * distincte de la clé iOS — à créer côté dashboard RevenueCat pour l'app Android, voir le
 * rapport de publication Play Store.
 */
object RevenueCatConfig {
    const val API_KEY = "goog_REPLACE_WITH_ANDROID_PUBLIC_API_KEY"
    const val ENTITLEMENT_ID = "ia_lifetime"
    const val AI_ENTITLEMENT_ID = "ia_feature"
    const val OFFERING_ID = "tips"
    const val AI_OFFERING_ID = "default"
}
