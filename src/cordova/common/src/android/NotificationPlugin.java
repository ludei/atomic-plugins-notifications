package com.ludei.notifications;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.Method;
import java.util.ArrayList;


public abstract class NotificationPlugin extends CordovaPlugin {

    public enum AppState {
        ACTIVE,
        LAUNCH,
        BACKGROUND
    }

	protected ArrayList<Notification> pendingNotifications = new ArrayList<Notification>();
    protected boolean ready = false;
    protected CallbackContext notificationListener;


    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();

        ready = false;
    }

    @Override
    public boolean execute(final String action, final CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
		//Run everything in the Main Thread
		this.cordova.getActivity().runOnUiThread(new Runnable() {
			@Override
			public void run() {
				try {
					final Method method = NotificationPlugin.this.getClass().getMethod(action, CordovaArgs.class, CallbackContext.class);
					method.invoke(NotificationPlugin.this, args, callbackContext);
				}
                catch (Exception e) {
					e.printStackTrace();
				} 
			}
		});

		return true;
    }


	protected void start() {

        ready = true;
        for (Notification notification: pendingNotifications) {
            processNotification(notification);
        }
	}


    protected void notifyNotificationReceived(JSONObject userData) {
        if (notificationListener != null) {
            PluginResult result = new PluginResult(Status.OK, userData);
            result.setKeepCallback(true);
            notificationListener.sendPluginResult(result);
        }
    }

    abstract protected void processNotification(Notification notification);

    //Common JS API

    @SuppressWarnings("unused")
    public void setListener(CordovaArgs args, CallbackContext ctx) {
        notificationListener = ctx;
    }


    @SuppressWarnings("unused")
    public void register(CordovaArgs args, CallbackContext ctx) {
        ctx.success();
    }

    @SuppressWarnings("unused")
    public void unregister(CordovaArgs args, CallbackContext ctx) {
        ctx.success();
    }

    @SuppressWarnings("unused")
    public void isRegistered(CordovaArgs args, CallbackContext ctx) {
        ctx.sendPluginResult(new PluginResult(Status.OK, true));
    }

	@SuppressWarnings("unused")
	public void subscribe(CordovaArgs args, CallbackContext ctx) {
		ctx.success();
	}

	@SuppressWarnings("unused")
	public void unsubscribe(CordovaArgs args, CallbackContext ctx) {
		ctx.success();
	}

	@SuppressWarnings("unused")
	public void fetchSubscribedChannels(CordovaArgs args, CallbackContext ctx) {
		ctx.success(new JSONArray());
	}

	@SuppressWarnings("unused")
	public void setBadgeNumber(CordovaArgs args, CallbackContext ctx) {
		ctx.success();
	}

	@SuppressWarnings("unused")
	public void getBadgeNumber(CordovaArgs args, CallbackContext ctx) {
		int a = 0;
		ctx.success(0);
	}

    //Utilities
    protected JSONObject errorToJSON(int code, String message) {
        JSONObject result = new JSONObject();
        try {
            result.put("code", code);
            result.put("message", message);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return result;
    }

    public static String fromAppStateToString(NotificationPlugin.AppState state) {
        switch (state) {
            case ACTIVE:
                return "active";
            case LAUNCH:
                return "launch";
            case BACKGROUND:
                return "background";
        }

        return "launch";
    }

}