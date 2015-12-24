package com.ludei.notifications.local;


import android.app.AlarmManager;
import android.app.Application;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;

import com.ludei.notifications.Notification;
import com.ludei.notifications.NotificationPlugin;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.HashMap;

public class NotificationLocalPlugin extends NotificationPlugin {


    protected HashMap<String, LocalNotification> scheduledNotifications = new HashMap<String, LocalNotification>();
    protected NotificationManager notificationManager;
    protected AlarmManager alarmManager;
    static final String NOTIFICATION_EXTRA_JSON = "com.ludei.notifications.local.extra.json";
    static final String NOTIFICATION_EXTRA_ACTIVITY = "com.ludei.notifications.local.extra.activity";
    static final int INTENT_REQUEST_CODE = 0x00024F6;
    private static boolean processedLaunchIntent = false;

    protected static AppState applicationState = AppState.LAUNCH;

    public static class LocalNotification extends Notification {

        private static int index = 1;
        public LocalNotification() {
            cocoonId = index++;
        }
        public int cocoonId;
        public PendingIntent pendingIntent;

        @Override
        public JSONObject toJSON() {
            JSONObject json = super.toJSON();
            try {
                json.put("cocoonId", cocoonId);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return json;
        }

        @Override
        public void fromJSONObject(JSONObject json) {
            super.fromJSONObject(json);
            this.cocoonId = json.optInt("cocoonId",this.cocoonId);
        }
    }

    @SuppressWarnings("unused")
    public static void onApplicationCreate(Application app) {
        applicationState = AppState.LAUNCH;
    }

    @SuppressWarnings("unused")
    public static void onApplicationTerminate(Application app) {
        applicationState = AppState.LAUNCH;
    }

	protected void pluginInitialize() {
        super.pluginInitialize();
        notificationManager = (NotificationManager) this.cordova.getActivity().getSystemService(Context.NOTIFICATION_SERVICE);
        alarmManager = (AlarmManager) this.cordova.getActivity().getSystemService(Context.ALARM_SERVICE);

        if (!processedLaunchIntent) {
            Intent intent = this.cordova.getActivity().getIntent();
            if (intent != null && intent.hasExtra(NOTIFICATION_EXTRA_JSON)) {
                LocalNotification notification = new LocalNotification();
                try {
                    notification.fromJSONObject(new JSONObject(intent.getStringExtra(NOTIFICATION_EXTRA_JSON)));
                    this.pendingNotifications.add(notification);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            processedLaunchIntent = true;
        }

        applicationState = AppState.ACTIVE;
	}

    @Override
    protected void processNotification(Notification notification) {

        scheduledNotifications.remove(notification.identifier);
        JSONObject userData = notification.userData;
        if (userData == null) {
            userData = new JSONObject();
        }
        userData.remove("cocoonId");
        notifyNotificationReceived(userData);
    }

    @Override
    public void onNewIntent(Intent intent) {
        if (intent.hasExtra(NOTIFICATION_EXTRA_JSON)) {
            String extra = intent.getStringExtra(NOTIFICATION_EXTRA_JSON);
            LocalNotification notification = new LocalNotification();
            try {
                notification.fromJSONObject(new JSONObject(extra));
            }
            catch (JSONException e) {
                e.printStackTrace();
                return;
            }

            if (this.ready) {
                this.processNotification(notification);
            }
            else {
                this.pendingNotifications.add(notification);
            }
        }
    }

    @Override
    public void onStart() {
        super.onStart();

        applicationState = AppState.ACTIVE;
    }

    @Override
    public void onStop() {
        super.onStop();

        applicationState = AppState.BACKGROUND;
    }

    //API

    @SuppressWarnings("unused")
    public void initialize(CordovaArgs args, CallbackContext ctx) {
        ctx.sendPluginResult(new PluginResult(PluginResult.Status.OK, true));
        super.start();
    }

    @SuppressWarnings("unused")
    public void send(CordovaArgs args, CallbackContext ctx) {

        JSONObject params = null;
        try {
            params = args.getJSONObject(0);
        }
        catch (JSONException ex) {
            ctx.error(errorToJSON(0, "Invalid notification argument"));
            return;
        }

        LocalNotification notification = new LocalNotification();
        notification.fromJSONObject(params);

        try {
            PackageManager pm = cordova.getActivity().getPackageManager();
            ApplicationInfo applicationInfo = pm.getApplicationInfo(cordova.getActivity().getComponentName().getPackageName(), PackageManager.GET_META_DATA);
            notification.icon = applicationInfo.icon;
            if (notification.contentTitle == null || notification.contentTitle.isEmpty()) {
                notification.contentTitle = pm.getApplicationLabel(applicationInfo).toString();
            }

        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }

        Intent intent = new Intent(this.cordova.getActivity(), LocalNotificationsReceiver.class);
        intent.putExtra(NOTIFICATION_EXTRA_JSON, notification.toJSON().toString());
        intent.putExtra(NOTIFICATION_EXTRA_ACTIVITY, this.cordova.getActivity().getClass().getName());

        notification.pendingIntent = PendingIntent.getBroadcast(this.cordova.getActivity(), notification.cocoonId, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        alarmManager.set(AlarmManager.RTC_WAKEUP, notification.date, notification.pendingIntent);

        scheduledNotifications.put(notification.identifier, notification);
        ctx.success();
    }

    @SuppressWarnings("unused")
    public void cancel(CordovaArgs args, CallbackContext ctx) {
        String identifier;
        try {
            identifier = args.getString(0);
        }
        catch (JSONException ex) {
            ctx.error(errorToJSON(0, "Invalid notification identifier"));
            return;
        }

        LocalNotification notification = scheduledNotifications.get(identifier);
        if (notification != null) {
            notificationManager.cancel(notification.cocoonId);
            if (notification.pendingIntent != null) {
                alarmManager.cancel(notification.pendingIntent);
            }
            scheduledNotifications.remove(identifier);
        }
        ctx.success();
    }

    @SuppressWarnings("unused")
    public void cancelAllNotifications(CordovaArgs args, CallbackContext ctx) {

        for (String identifier: scheduledNotifications.keySet()) {
            LocalNotification notification = scheduledNotifications.get(identifier);
            notificationManager.cancel(notification.cocoonId);
            if (notification.pendingIntent != null) {
                alarmManager.cancel(notification.pendingIntent);
            }
        }
        scheduledNotifications.clear();
        ctx.success();
    }
}