package com.ludei.notifications.local;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;

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

			} catch (JSONException e) {
				e.printStackTrace();
			}
			data.fromJSONObject(obj);
		}

		if (NotificationLocalPlugin.applicationState == NotificationPlugin.AppState.ACTIVE) {
			Intent notificationIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
			notificationIntent.putExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON, obj.toString());
			context.startActivity(notificationIntent);

			return;
		}

		Intent notificationIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
		notificationIntent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
		notificationIntent.putExtra(NotificationLocalPlugin.NOTIFICATION_EXTRA_JSON, extra);

		PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		String contentBody = data.contentBody == null ? "" : data.contentBody;
		String tickerText = String.format(Locale.getDefault(), "%s: %s", data.message, contentBody);

		Notification notification;
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN) {
			notification = new android.app.Notification();
			notification.when = data.date;
			notification.tickerText = tickerText;
			notification.flags |= android.app.Notification.FLAG_SHOW_LIGHTS | android.app.Notification.FLAG_AUTO_CANCEL;
			notification.defaults |= android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
			if (data.soundEnabled) {
				notification.defaults |= android.app.Notification.DEFAULT_SOUND;
			}
			notification.icon = data.icon;
			notification.contentIntent = contentIntent;
			notification.setLatestEventInfo(context, data.message, contentBody, contentIntent);

		} else {
			int defaults = android.app.Notification.DEFAULT_LIGHTS | android.app.Notification.DEFAULT_VIBRATE;
			if (data.soundEnabled) {
				defaults |= android.app.Notification.DEFAULT_SOUND;
			}
			notification = new Notification.Builder(context)
					.setContentTitle(data.message)
					.setContentText(contentBody)
					.setSmallIcon(data.icon)
					.setDefaults(defaults)
					.setAutoCancel(true)
					.setContentIntent(contentIntent)
					.build();
		}

		NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
		notificationManager.notify(data.cocoonId, notification);
	}

}
