package com.matthiascadet.holyday.ui.navigation

object NavRoutes {
    const val ONBOARDING = "onboarding"
    const val MAIN = "main"
    const val FREE_PRAYER = "freePrayer"
    const val STRUCTURED_PRAYER = "structuredPrayer"
    const val INTENTIONS = "intentions"
    const val INTENTION_DETAIL = "intentions/{intentionId}"
    fun intentionDetail(id: String) = "intentions/$id"
    const val JOURNAL_ENTRY = "journalEntry/{entryId}"
    fun journalEntry(id: String) = "journalEntry/$id"
    const val JOURNAL_STATS = "journalStats"
    const val LEGAL = "legal"
    const val PAYWALL = "paywall"
    const val DONATION_THANK_YOU = "donationThankYou?tier={tier}"
    fun donationThankYou(tier: String?) = "donationThankYou?tier=${tier ?: ""}"
    const val SUPPORT_PROMPT = "supportPrompt"
    const val DEBUG_MENU = "debugMenu"
}
