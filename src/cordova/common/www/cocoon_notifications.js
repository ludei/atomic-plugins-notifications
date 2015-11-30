(function(){

    if (!window.Cocoon && window.cordova && typeof require !== 'undefined') {
        cordova.require('cocoon-plugin-common.Cocoon');
    }
    var Cocoon = window.Cocoon;

    /**
     * This namespace represents the Cocoon Notification extension for local and remote notifications.
     * @namespace Cocoon.Notification
     * @example 
     * //Set up notification listener
     * Cocoon.Notification.Local.on("notification", function(userData){
     *      console.log("A local notification has been received: " + JSON.stringify(userData));
     * });
     *
     * Cocoon.Notification.Local.initialize(); //ready to start receiving notification callbacks
     *
     * // Register the application to receive notifications. It may show a Dialog to request user permissions.
     * Cocoon.Notification.Local.register({}, function(error) {
     *  if (error) {
     *      alert('Notifications disabled by user')
     *  }
     *  else {
     *      sendNotification(); 
     *  }
     * })
     *
     * function sendNotification() {
     *     var notification = {
     *      message : "Hi, I am a notification",
     *      soundEnabled : true,
     *      badgeNumber : 0,
     *      userData : {"key1" : "value1", "key2": "value2"},
     *      contentBody : "",
     *      contentTitle : "",
     *      date : new Date().valueOf() + 1000
     *     };
     *
     *     Cocoon.Notification.Local.send(notification);
     * }
     */
    Cocoon.define("Cocoon.Notification", function(extension) {
        "use strict";

        function NotificationService(serviceName) {
        	this.serviceName = serviceName;
        	this.signal = new Cocoon.Signal();
            this.idIndex = 0;
            /**
             * Allows to listen to events when the application receives a notification.
             * @memberOf Cocoon.Notification
             * @event On notification
             * @example
             * Cocoon.Notification.Local.on("notification", function(data) {
             *      console.log('Local notification received: ' + JSON.stringify(data));
             * });
             * Cocoon.Notification.Parse.on("notification", function(data) {
             *      console.log('Remote notification received: ' + JSON.stringify(data));
             * });
             */
            this.on = this.signal.expose();
        }

        extension.NotificationService = NotificationService;
        var proto = NotificationService.prototype;



        /**
         * Starts the Notification Service. The notification callbacks will start to be received after calling this method.
         * Because of this, you should have set your event handler before calling this method, so you won't lose any callback.
         * @memberof Cocoon.Notification.NotificationService
         * @function initialize
         */
        proto.initialize = function() {
            var me = this;
            Cocoon.exec(this.serviceName, "setListener", [], function(data) {
                me.signal.emit('notification', null, [data]);
            });
            Cocoon.exec(this.serviceName, 'initialize', []);
        };


        /**
         * Checks if user has permission to receive notifications
         * @function canReceiveNotifications
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Function} callback The callback function. It receives the following parameters:
         * - granted {Boolean} True if the user has permission to receive notifications
         */
        proto.isRegistered = function(callback) {
            Cocoon.exec(this.serviceName, "isRegistered", [], callback, callback);
        };

        /**
         * Registers the application to be able to receive push notifications. In some systems like iOS it shows a dialog to request user permission.
         * @function register
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Object} params
         * @param {Function} callback The callback function. It receives the following parameters:
         * - Error.
         */
        proto.register = function(params, callback) {
            Cocoon.exec(this.serviceName, 'register', [params], callback, callback);
        },

        /**
        * Unregisters the application from receiving push notifications
         * @function unregister
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Object} params
         * @param {Function} callback The callback function. It receives the following parameters:
         * - Error.
         */
        proto.unregister = function(callback) {
            Cocoon.exec(this.serviceName, 'unregister', [], callback, callback);
        };


        /**
         * Send notification
         * @function send
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Cocoon.Notification.NotificationInfo} notification The notification to sends
         * @param {Function} callback The delivery callback function. It receives the following parameters:
         * - Error.
         */
        proto.send = function(notification, callback) {
            var identifier = this.idIndex++ + '';
            notification.id = identifier;
            Cocoon.exec(this.serviceName, 'send', [identifier, notification], callback, callback);
            return identifier;
        };

        /**
         * Subscribes to a channel in order to receive notifications targeted to that channel.
         * @function subscribe
         * @memberOf Cocoon.Notification.NotificationService
         * @param {string} channel The channel id
         * @param {Function} callback The subscribe succeeded callback function. It receives the following parameters:
         * - Error.
         */
        proto.subscribe = function(channel, callback) {
            Cocoon.exec(this.serviceName, 'subscribe', [channel], callback, callback);
        };

        /**
         * Unsubscribes from a channel in order to stop receiving notifications targeted to it.
         * @function unsubscribe
         * @memberOf Cocoon.Notification.NotificationService
         * @param {string} channel The channel id
         * @param {Function} callback The unsubscribe succeeded callback function. It receives the following parameters:
         * - Error.
         */
        proto.unsubscribe = function(channel, callback) {
            Cocoon.exec(this.serviceName, 'unsubscribe', [channel], callback, callback);
        };

        /**
         * Cancels the local notification with Id provided
         * @function cancel
         * @memberOf Cocoon.Notification.NotificationService
         * @param {string}  The notification id
         */
        proto.cancel = function(notificationId) {
            Cocoon.exec(this.serviceName, 'cancel', [notificationId]);
        };

        /**
         * Cancels all the pending notifications
         * @function cancelAllNotifications
         * @memberOf Cocoon.Notification.NotificationService
         */
        proto.cancelAllNotifications = function() {
            Cocoon.exec(this.serviceName, 'cancelAllNotifications', []);
        };

        /**
         * (iOS only) Sets the badge number for this application.
         * @function setBadgeNumber
         * @memberOf Cocoon.Notification.NotificationService
         * @param {number} badgeNumber The badge number
         */
        proto.setBadgeNumber = function(badgeNumber) {
            Cocoon.exec(this.serviceName, 'setBadgeNumber', [badgeNumber]);
        };

        /**
         * (iOS only) Gets the current badge number.
         * @function getBadgeNumber
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Function} callback The callback to get badgeNumber. It receives the following parameters:
         * - badgeNumber.
         */
        proto.getBadgeNumber = function(callback) {
            Cocoon.exec(this.serviceName, 'getBadgeNumber', [], callback);
        };


        /**
         * The object that represents the information of a notification.
         * @memberof Cocoon.Notification
         * @name Cocoon.Notification.NotificationInfo
         * @property {object} Cocoon.Notification.NotificationInfo - The object itself
         * @property {string}   Cocoon.Notification.NotificationInfo.id The notification identifier. Autogenerated.
         * @property {string}   Cocoon.Notification.NotificationInfo.title The notification message. By default, it will be empty. 
         * @property {string}   Cocoon.Notification.NotificationInfo.message The notification title. By default, it will be empty. 
         * @property {boolean}  Cocoon.Notification.NotificationInfo.soundEnabled A flag that indicates if the sound should be enabled for the notification. By default, it will be true. 
         * @property {number}   Cocoon.Notification.NotificationInfo.badgeNumber The number that will appear in the badge of the application icon in the home screen. By default, it will be 0. 
         * @property {object}   Cocoon.Notification.NotificationInfo.userData The JSON data to attached to the notification. By default, it will be empty. 
         * @property {string}   Cocoon.Notification.NotificationInfo.contentBody The body content to be showed in the expanded notification information. By default, it will be empty. 
         * @property {string}   Cocoon.Notification.NotificationInfo.contentTitle The title to be showed in the expanded notification information. By default, it will be empty. 
         * @property {number}   Cocoon.Notification.NotificationInfo.date Time in millisecs from 1970 when the notification will be fired. By default, it will be 1 second (1000).
         */
        extension.NotificationInfo = {
            id: 0,
            title: "",
            message: "",
            soundEnabled: true,
            badgeNumber: 0,
            userData: {},
            contentBody: "",
            contentTitle: "",
            date: 0
        };

        return extension;
    });
})();
