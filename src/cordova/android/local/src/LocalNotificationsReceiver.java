package com.ludei.notifications.local;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import org.json.JSONObject;

public class LocalNotificationsReceiver extends BroadcastReceiver {

	@Override
	public void onReceive(Context context, Intent intent) {
		try {
			if (intent == null) {
				return;
			}


			NotificationLocalPlugin.LocalNotification data = new NotificationLocalPlugin.LocalNotification();
			String extra = intent.getStringExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON);
			if (extra != null) {
				JSONObject obj = new JSONObject(extra);
				data.fromJSONObject(obj);
			}


			android.app.Notification notification = new android.app.Notification();
			notification.when = data.date;
			notification.tickerText = data.message;
			notification.flags |= android.app.Notification.FLAG_SHOW_LIGHTS | android.app.Notification.FLAG_AUTO_CANCEL;
			notification.defaults |= android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
			if (data.soundEnabled) {
				notification.defaults |= android.app.Notification.DEFAULT_SOUND;
			}
			notification.icon = data.icon;

			String activityClassName = intent.getStringExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_ACTIVITY);

			Intent notificationIntent = new Intent(context, Class.forName(activityClassName));
			notificationIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
			notificationIntent.putExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON, extra);

			PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
			String contentBody = data.contentBody == null ? "" : data.contentBody;
			notification.setLatestEventInfo(context, data.contentTitle, contentBody, contentIntent);

			NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
			notificationManager.notify(data.cocoonId, notification);
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}

}
