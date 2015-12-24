package com.ludei.notifications.parse;


import android.app.Application;
import android.content.Intent;

import com.ludei.notifications.Notification;
import com.ludei.notifications.NotificationPlugin;
import com.parse.Parse;
import com.parse.ParseException;
import com.parse.ParseInstallation;
import com.parse.ParsePush;
import com.parse.SaveCallback;
import com.parse.SendCallback;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

public class NotificationParsePlugin extends NotificationPlugin {


    private static boolean processedLaunchIntent = false;
    protected static AppState applicationState = AppState.LAUNCH;

    public static class ParseNotification extends Notification {
        public int expirationTimeInterval = 0;
        public int expirationTime = 0;
        public JSONArray channels = new JSONArray();

        @Override
        public JSONObject toJSON() {
            JSONObject json = super.toJSON();
            try {
                json.put("expirationTimeInterval", expirationTimeInterval);
                json.put("expirationTime", expirationTime);
                json.put("channels", this.channels != null ? this.channels : new JSONArray());
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return json;
        }

        @Override
        public void fromJSONObject(JSONObject json) {
            super.fromJSONObject(json);
            this.expirationTimeInterval = json.optInt("expirationTimeInterval",this.expirationTimeInterval);
            this.expirationTime = json.optInt("expirationTime",this.expirationTime);
            this.channels = json.optJSONArray("channels");
            if (this.channels == null) {
                this.channels = new JSONArray();
            }
        }

    }

    @SuppressWarnings("unused")
    public static void onApplicationCreate(Application app) {
        applicationState = AppState.LAUNCH;

        String appId = getStringByKey(app, "parse_app_id");
        String clientKey = getStringByKey(app, "parse_client_key");

        Parse.enableLocalDatastore(app);
        Parse.initialize(app, appId, clientKey);
        ParseInstallation.getCurrentInstallation().saveInBackground();
    }

    @SuppressWarnings("unused")
    public static void onApplicationTerminate(Application app) {
        applicationState = AppState.LAUNCH;
    }

    private static String getStringByKey(Application app, String key) {
        int resourceId = app.getResources().getIdentifier(key, "string", app.getPackageName());
        return app.getString(resourceId);
    }

	protected void pluginInitialize() {
        super.pluginInitialize();

        if (!processedLaunchIntent) {
            Intent intent = this.cordova.getActivity().getIntent();
            ParseNotification launchNotification = fromIntent(intent);
            if (launchNotification != null) {
                this.pendingNotifications.add(launchNotification);
            }
            processedLaunchIntent = true;
        }

        applicationState = AppState.ACTIVE;
	}

    protected ParseNotification fromIntent(Intent intent) {
        if (intent != null && intent.hasExtra("com.parse.Data")) {
            String extra = intent.getStringExtra("com.parse.Data");
            ParseNotification notification = new ParseNotification();
            try {
                notification.userData = new JSONObject(extra);
                return notification;
            }
            catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    @Override
    protected void processNotification(Notification notification) {

        JSONObject userData = notification.userData;
        if (userData == null) {
            userData = new JSONObject();
        }
        notifyNotificationReceived(userData);
    }

    @Override
    public void onNewIntent(Intent intent) {
        ParseNotification notification = fromIntent(intent);
        if (notification != null) {
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
    public void send(CordovaArgs args, final CallbackContext ctx) {

        JSONObject params = null;
        try {
            params = args.getJSONObject(0);
        }
        catch (JSONException ex) {
            ctx.error(errorToJSON(0, "Invalid notification argument"));
            return;
        }

        ParseNotification notification = new ParseNotification();
        notification.fromJSONObject(params);

        ParsePush push = new ParsePush();
        push.setMessage(notification.message != null ? notification.message : "");
        if (notification.expirationTime != 0) {
            push.setExpirationTime(notification.expirationTime);
        }
        if (notification.expirationTimeInterval != 0) {
            push.setExpirationTimeInterval(notification.expirationTimeInterval);
        }
        if (notification.channels != null && notification.channels.length() > 0) {
            ArrayList<String> list = new ArrayList<String>();
            for (int i = 0; i < notification.channels.length(); ++i) {
                try {
                    list.add(notification.channels.getString(i));
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            push.setChannels(list);
        }

        try {
            JSONObject userData = notification.userData != null ? notification.userData : new JSONObject();
            if (notification.soundEnabled) {
                userData.put("sound", "default");
            }
            userData.put("alert", notification.message != null ? notification.message : "");
            push.setData(userData);
        }
        catch (JSONException ex) {
            ex.printStackTrace();
        }

        push.sendInBackground(new SendCallback() {
            @Override
            public void done(ParseException e) {
                if (e == null) {
                    ctx.success();
                } else {
                    ctx.error(errorToJSON(e.getCode(), e.getLocalizedMessage()));
                }
            }
        });
    }

    @SuppressWarnings("unused")
    public void subscribe(CordovaArgs args, final CallbackContext ctx) {
        try {
            String channel = args.getString(0);

            ParsePush.subscribeInBackground(channel, new SaveCallback() {
                @Override
                public void done(ParseException e) {
                    if (e == null) {
                        ctx.success();
                    }
                    else {
                        ctx.error(errorToJSON(e.getCode(), e.getLocalizedMessage()));
                    }
                }
            });

        }
        catch (JSONException e) {
            ctx.error(errorToJSON(0, "Invalid channel"));
        }
    }

    @SuppressWarnings("unused")
    public void unsubscribe(CordovaArgs args, final CallbackContext ctx) {
        try {
            String channel = args.getString(0);

            ParsePush.unsubscribeInBackground(channel, new SaveCallback() {
                @Override
                public void done(ParseException e) {
                    if (e == null) {
                        ctx.success();
                    }
                    else {
                        ctx.error(errorToJSON(e.getCode(), e.getLocalizedMessage()));
                    }
                }
            });

        }
        catch (JSONException e) {
            ctx.error(errorToJSON(0, "Invalid channel"));
        }
    }


    @SuppressWarnings("unused")
    public void cancel(CordovaArgs args, CallbackContext ctx) {
        ctx.error(errorToJSON(0, "Not possible to cancel already sent client push notifications in Parse"));
    }

    @SuppressWarnings("unused")
    public void cancelAllNotifications(CordovaArgs args, CallbackContext ctx) {
        ctx.error(errorToJSON(0, "Not possible to cancel already sent client push notifications in Parse"));
    }
}