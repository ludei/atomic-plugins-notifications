package com.ludei.notifications.local;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;

import com.ludei.notifications.NotificationPlugin;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;

public class LocalNotificationsReceiver extends BroadcastReceiver {

	@Override
	public void onReceive(Context context, Intent intent) {
		if (intent == null) {
			return;
		}

		NotificationLocalPlugin.LocalNotification data = new NotificationLocalPlugin.LocalNotification();
		String extra = intent.getStringExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON);
		JSONObject obj = new JSONObject();
		if (extra != null) {
			try {
				obj = new JSONObject(extra);
				JSONObject userData = obj.getJSONObject("userData");
				userData.put("applicationState", NotificationPlugin.fromAppStateToString(NotificationLocalPlugin.applicationState));
				extra = obj.toString();

			} catch (JSONException e) {}
			data.fromJSONObject(obj);
		}

		String activityClassName = intent.getStringExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_ACTIVITY);
		if (NotificationLocalPlugin.applicationState == NotificationPlugin.AppState.ACTIVE) {
			Intent notificationIntent = new Intent().setClassName(context, activityClassName);
			notificationIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_MULTIPLE_TASK);
			notificationIntent.putExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON, obj.toString());
			context.startActivity(notificationIntent);

			return;
		}

		Intent notificationIntent = new Intent().setClassName(context, activityClassName);
		notificationIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
		notificationIntent.putExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON, extra);

		PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		String contentBody = data.contentBody == null ? "" : data.contentBody;

		Notification notification;
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN) {
			int defaults = android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
			if (data.soundEnabled) {
				defaults |= android.app.Notification.DEFAULT_SOUND;
			}
			notification = new NotificationCompat.Builder(context)
					.setContentTitle(data.message)
					.setContentText(contentBody)
					.setSmallIcon(Integer.parseInt(data.icon))
					.setDefaults(defaults)
					.setAutoCancel(true)
					.setContentIntent(contentIntent)
					.build();

		} else {
			int defaults = android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
			if (data.soundEnabled) {
				defaults |= android.app.Notification.DEFAULT_SOUND;
			}
			notification = new Notification.Builder(context)
					.setContentTitle(data.message)
					.setContentText(contentBody)
					.setSmallIcon(Integer.parseInt(data.icon))
					.setDefaults(defaults)
					.setAutoCancel(true)
					.setContentIntent(contentIntent)
					.build();
		}

		NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
		notificationManager.notify(data.cocoonId, notification);
	}

}
