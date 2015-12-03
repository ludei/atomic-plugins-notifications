package com.ludei.notifications.parse;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import com.parse.ParsePushBroadcastReceiver;
import org.json.JSONObject;

import java.util.Locale;

public class ParseCustomBroadcastReceiver extends ParsePushBroadcastReceiver {

    /*
    * Custom onReceive test to avoid activity killed when user clicks notification, but doesn't work :-/
    */
    /*@Override
    public void onReceive(Context context, Intent intent) {
        try {
            if (intent == null) {
                return;
            }

            String extras = intent.getStringExtra("com.parse.Data");
            JSONObject pushData = new JSONObject(extras);
            if (pushData == null || (!pushData.has("alert") && !pushData.has("title"))) {
                return;
            }

            ApplicationInfo appInfo = context.getApplicationInfo();
            String title = pushData.optString("title");
            if (title == null || title.isEmpty()) {
                title = context.getPackageManager().getApplicationLabel(appInfo).toString();
            }
            String alert = pushData.optString("alert", "Notification received.");
            String tickerText = String.format(Locale.getDefault(), "%s: %s", title, alert);

            android.app.Notification notification = new android.app.Notification();
            notification.tickerText = tickerText;
            notification.flags |= android.app.Notification.FLAG_SHOW_LIGHTS | android.app.Notification.FLAG_AUTO_CANCEL;
            notification.defaults |= android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
            if (pushData.optString("sound") != null) {
                notification.defaults |= android.app.Notification.DEFAULT_SOUND;
            }
            notification.icon = appInfo.icon; // getSmallIconId(context, intent);
            //notification.largeIcon = getLargeIcon(context, intent);


            Intent notificationIntent = new Intent(context, Class.forName("com.ludei.devapp.MainActivity"));/// getActivity(context, intent));
            notificationIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
            //notificationIntent.putExtras(intent.getExtras());

            PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
            notification.setLatestEventInfo(context, title, alert, contentIntent);

            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            // Pick an id that probably won't overlap anything
            int notificationId = (int)System.currentTimeMillis();
            notificationManager.notify(notificationId, notification);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }*/


    @Override
    public void onPushDismiss(Context context, Intent intent)
    {

    }

    @Override
    public void onPushOpen(Context context, Intent intent)
    {
        super.onPushOpen(context, intent);
    }
}