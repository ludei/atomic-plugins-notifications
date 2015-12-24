(function(){

    if (window.cordova && typeof require !== 'undefined') {
        require('cocoon-plugin-notifications-common.Notifications'); //force dependency load
    }
    var Cocoon = window.Cocoon;

    /**
     * This namespace represents the Cocoon Notification extension for push notifications using Parse
     * @namespace Cocoon.Notification.Parse
     *
     * @example
     * //Set up notification listener
     * Cocoon.Notification.Parse.on(notification, function(userData){
     *      console.log("A push notification has been received: " + JSON.stringify(userData));
     * });
     *
     * // Initialize the service. Ready to start receiving notification callbacks
     * // Auto register the application to receive notifications. It may show a Dialog to request user permissions.
     * // For Android the initialization parameters shouldbe passed as commandline argument APP_ID and CLIENT_KEY.
     * // You can disable autoregister witht {register:false} params and call Cocoon.Notification.Local.register() manually
     *
     * Cocoon.Notification.Parse.initialize({appId:'aaaa', clientKey:'xxxx'}, function(registered) {
     *  if (!registered) {
     *      alert('Push notifications disabled by user')
     *  }
     *  else {
     *      subscribeRemoteChannel();
     *  }
     * })
     *
     * function subscribeRemoteChannel() {
     *
     * }
     */
    Cocoon.define("Cocoon.Notification", function(extension) {

        extension.Parse = new Cocoon.Notification.NotificationService('LDNotificationParsePlugin');
        return extension;
    });
})();
