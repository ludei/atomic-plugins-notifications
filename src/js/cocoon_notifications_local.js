(function(){

    if (window.cordova && typeof require !== 'undefined') {
        require('cocoon-plugin-notifications-common.Notifications'); //force dependency load
    }
    var Cocoon = window.Cocoon;

    /**
     * This namespace represents the Cocoon Notification extension for local notifications
     * @namespace Cocoon.Notification.Local
     *
     * @example
     * //Set up notification listener
     * Cocoon.Notification.Local.on(notification, function(userData){
     *      console.log("A local notification has been received: " + JSON.stringify(userData));
     * });
     *
     * // Initialize the service. Ready to start receiving notification callbacks
     * // Auto register the application to receive notifications. It may show a Dialog to request user permissions.
     * // You can disable autoregister witht {register:false} params and call Cocoon.Notification.Local.register() manually
     *
     * Cocoon.Notification.Local.initialize({appId:'aaaa', clientKey:'xxxx'}, function(registered) {
     *  if (!registered) {
     *      alert('Local notifications disabled by user')
     *  }
     * })
     */
    Cocoon.define("Cocoon.Notification", function(extension) {

        extension.Local = new Cocoon.Notification.NotificationService('LDNotificationLocalPlugin');

        return extension;
    });
})();
