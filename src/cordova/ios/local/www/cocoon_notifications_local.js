(function(){

    if (window.cordova && typeof require !== 'undefined') {
        require('cocoon-plugin-notifications-common.Notifications'); //force dependency load
    }
    var Cocoon = window.Cocoon;

    /**
     * Cocoon Local Notifications Implementation
     * @namespace Cocoon.Notification.Local
     */
    Cocoon.define("Cocoon.Notification", function(extension) {

        extension.Local = new Cocoon.Notification.NotificationService('LDNotificationLocalPlugin');

        return extension;
    });
})();
