package com.matthiascadet.holyday.service.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.matthiascadet.holyday.data.prefs.AppPreferences

/** Reprogramme le rappel quotidien après un redémarrage (les alarmes exactes sont effacées). */
class BootRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        AppPreferences.init(context)
        NotificationService.init(context)
        NotificationService.refreshScheduledReminders(context)
    }
}
