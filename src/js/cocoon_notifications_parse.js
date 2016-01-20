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
     * // The initialization parameters should be passed as commandline argument APP_ID and CLIENT_KEY or using the Cocoon cloud plugin parameters.
     * // The service will be automatically registered after the initialization. This may show a Dialog to request user permissions.
     * // You can disable autoregister with {register: false} params and call Cocoon.Notification.Local.register() manually to control when the permissions dialog is shown.
     * // By default the register parameter is set to true.
     *
     * Cocoon.Notification.Parse.initialize({register: false}, function(registered) {
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
