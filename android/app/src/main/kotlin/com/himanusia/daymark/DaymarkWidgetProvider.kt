package com.himanusia.daymark

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class DaymarkWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateAll(context, appWidgetIds)
    }

    companion object {
        private const val WIDGET_PREFS = "daymark_widget"
        private const val KEY_TITLE = "title"
        private const val KEY_COUNTDOWN = "countdown"
        private const val KEY_STATUS = "status"

        fun updateAll(context: Context, widgetIds: IntArray? = null) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = widgetIds ?: manager.getAppWidgetIds(
                ComponentName(context, DaymarkWidgetProvider::class.java),
            )
            ids.forEach { widgetId ->
                manager.updateAppWidget(widgetId, buildRemoteViews(context))
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val preferences = context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
            val title = preferences.getString(KEY_TITLE, null).orEmpty()
                .ifBlank { "Add a mark in H- Countdown" }
            val countdown = preferences.getString(KEY_COUNTDOWN, null).orEmpty()
                .ifBlank { "—" }
            val status = preferences.getString(KEY_STATUS, null).orEmpty()
                .ifBlank { "FOCUS" }

            val views = RemoteViews(context.packageName, R.layout.daymark_widget)
            views.setTextViewText(R.id.widget_status, status.uppercase())
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_countdown, countdown)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            var pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                pendingFlags = pendingFlags or PendingIntent.FLAG_IMMUTABLE
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                pendingFlags,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            return views
        }
    }
}
