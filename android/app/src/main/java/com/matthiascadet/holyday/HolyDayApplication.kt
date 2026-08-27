package com.matthiascadet.holyday

import android.app.Application
import com.matthiascadet.holyday.data.prefs.AppPreferences
import com.matthiascadet.holyday.service.PrayerRecordService
import com.matthiascadet.holyday.service.TipService
import com.matthiascadet.holyday.service.WidgetSyncService
import com.matthiascadet.holyday.service.notification.NotificationService
import com.matthiascadet.holyday.ui.theme.RevenueCatConfig
import com.revenuecat.purchases.LogLevel
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration

class HolyDayApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        AppPreferences.init(this)
        WidgetSyncService.init(this)

        Purchases.logLevel = if (BuildConfig.DEBUG) LogLevel.DEBUG else LogLevel.ERROR
        Purchases.configure(PurchasesConfiguration.Builder(this, RevenueCatConfig.API_KEY).build())

        PrayerRecordService.refresh()
        TipService.init()
        NotificationService.init(this)
    }
}
