package com.matthiascadet.holyday.ui.theme

/** Équivalent de `AppLinks` (HolyDay/Theme/AppConstants.swift). */
object AppLinks {
    const val PRIVACY_POLICY = "https://holyday-landing.vercel.app/privacy.html"
    const val TERMS_OF_SERVICE = "https://holyday-landing.vercel.app/terms.html"
    const val PLAY_STORE = "https://play.google.com/store/apps/details?id=com.matthiascadet.holyday"
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
