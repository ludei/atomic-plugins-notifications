package com.ludei.notifications.parse;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.res.Resources;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import com.ludei.notifications.NotificationPlugin;
import com.parse.ParsePushBroadcastReceiver;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;

public class ParseCustomBroadcastReceiver extends ParsePushBroadcastReceiver {

    @Override
    public void onPushReceive(Context context, Intent intent) {
        if (intent == null) {
            return;
        }

        String extras = intent.getStringExtra("com.parse.Data");
        JSONObject pushData = null;
        try {
            pushData = new JSONObject(extras);
            pushData.put("applicationState", NotificationPlugin.fromAppStateToString(NotificationParsePlugin.applicationState));

        } catch (JSONException e) {
            e.printStackTrace();
        }
        if (pushData == null || (!pushData.has("alert") && !pushData.has("title"))) {
            return;
        }

        if (NotificationParsePlugin.applicationState == NotificationPlugin.AppState.ACTIVE) {
            Intent notificationIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            Bundle bundle = intent.getExtras();
            bundle.putString("com.parse.Data", pushData.toString());
            notificationIntent.putExtras(bundle);
            context.startActivity(notificationIntent);

            return;
        }

        ApplicationInfo appInfo = context.getApplicationInfo();
        String title = pushData.optString("title");
        if (title == null || title.isEmpty()) {
            title = context.getPackageManager().getApplicationLabel(appInfo).toString();
        }

        Intent notificationIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        Bundle bundle = intent.getExtras();
        bundle.putString("com.parse.Data", pushData.toString());
        notificationIntent.putExtras(bundle);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        String alert = pushData.optString("alert", "Notification received.");
        String tickerText = String.format(Locale.getDefault(), "%s: %s", title, alert);

        int iconResId = getSmallIconId(context, intent);
        try {
            String icon = pushData.getString("icon");
            if (!icon.isEmpty()) {
                int resourceId = context.getResources().getIdentifier(icon, "drawable", context.getPackageName());
                iconResId = resourceId;
            }

        } catch(Exception e) {}

        Notification notification;
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN) {
            notification = new android.app.Notification();
            notification.tickerText = tickerText;
            notification.flags |= android.app.Notification.FLAG_SHOW_LIGHTS | android.app.Notification.FLAG_AUTO_CANCEL;
            notification.defaults |= android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
            if (pushData.optString("sound") != null) {
                notification.defaults |= android.app.Notification.DEFAULT_SOUND;
            }
            notification.icon = iconResId;
            notification.largeIcon = getLargeIcon(context, intent);
            notification.contentIntent = contentIntent;
            notification.setLatestEventInfo(context, title, alert, contentIntent);

        } else {
            int defaults = android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
            if (pushData.optString("sound") != null) {
                defaults |= android.app.Notification.DEFAULT_SOUND;
            }
            notification = new Notification.Builder(context)
                    .setContentTitle(title)
                    .setContentText(alert)
                    .setSmallIcon(iconResId)
                    .setLargeIcon(getLargeIcon(context, intent))
                    .setDefaults(defaults)
                    .setAutoCancel(true)
                    .setContentIntent(contentIntent)
                    .build();
        }

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        // Pick an id that probably won't overlap anything
        int notificationId = (int)System.currentTimeMillis();
        notificationManager.notify(notificationId, notification);
    }

    @Override
    public void onPushDismiss(Context context, Intent intent) {
        super.onPushDismiss(context, intent);
    }

    @Override
    public void onPushOpen(Context context, Intent intent) {
        super.onPushOpen(context, intent);
    }
}