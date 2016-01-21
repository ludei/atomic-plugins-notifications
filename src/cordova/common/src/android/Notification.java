package com.ludei.notifications;

import android.app.PendingIntent;

import org.json.JSONException;
import org.json.JSONObject;

public abstract class Notification {
	
	public String identifier;
	public String message;
	public String contentTitle;
    public String contentBody;
	public boolean soundEnabled = true;
	public long date;
	public int badgeNumber;
	public JSONObject userData;
    public String icon;
    public PendingIntent pendingIntent;

    private static final String NOTIFICATION_EXTRA = "com.ludei.notifications.extra";


    public JSONObject toJSON() {
        JSONObject json = new JSONObject();
        try {
            json.putOpt("id", identifier);
            json.putOpt("message", message);
            json.putOpt("contentTitle", contentTitle);
            json.putOpt("contentBody", contentBody);
            json.put("soundEnabled", soundEnabled);
            json.put("date", date);
            json.put("badgeNumber", badgeNumber);
            json.put("icon", icon);
            json.putOpt("userData", userData);
        }
        catch (JSONException ex) {
            ex.printStackTrace();
        }
        return json;
    }

    public void fromJSONObject(JSONObject json) {
        this.identifier = json.optString("id", this.identifier);
        this.message = json.optString("message", this.message);
        this.contentTitle = json.optString("contentTitle", this.contentTitle);
        this.contentBody = json.optString("contentBody", this.contentBody);
        this.soundEnabled = json.optBoolean("soundEnabled", this.soundEnabled);
        this.date = json.optLong("date", this.date);
        this.badgeNumber = json.optInt("badgeNumber", this.badgeNumber);
        this.userData = json.optJSONObject("userData");
        this.icon = json.optString("icon", this.icon);
    }

}
