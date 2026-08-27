package com.matthiascadet.holyday.service.notification

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.matthiascadet.holyday.MainActivity
import com.matthiascadet.holyday.R
import com.matthiascadet.holyday.data.prefs.AppPreferences
import java.time.LocalDate

/** Poste le rappel quotidien puis replanifie celui de demain (voir `NotificationService`). */
class PrayerReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        ensureChannel(context)

        val userName = AppPreferences.raw.getString(NotificationService.USER_NAME_KEY, "")?.trim() ?: ""
        val (title, body) = NotificationService.reminderContent(context, LocalDate.now(), userName)

        val hasPermission = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

        if (hasPermission) {
            val openIntent = Intent(context, MainActivity::class.java).apply {
                data = android.net.Uri.parse("holyday://pray")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, openIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
            )

            val notification = NotificationCompat.Builder(context, NotificationService.CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()

            androidx.core.app.NotificationManagerCompat.from(context)
                .notify(NotificationService.NOTIFICATION_ID, notification)
        }

        // Replanifie systématiquement demain, que la notif ait pu être postée ou non (permission
        // révoquée entre-temps) : si l'utilisateur réautorise plus tard, la chaîne repart au
        // prochain `refreshScheduledReminders`.
        NotificationService.scheduleNext(context, NotificationService.reminderTime.value)
    }

    private fun ensureChannel(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            NotificationService.CHANNEL_ID,
            context.getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        manager.createNotificationChannel(channel)
    }
}
