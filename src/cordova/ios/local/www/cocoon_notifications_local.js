(function(){

    if (!window.Cocoon && window.cordova && typeof require !== 'undefined') {
        cordova.require('cocoon-plugin-common.Cocoon');
    }
    var Cocoon = window.Cocoon;

    /**
     * This namespace represents the Cocoon Notification extension for local and remote notifications.
     * @namespace Cocoon.Notification
     * @example 
     * Cocoon.Notification.Local.on("notification", function(userData){
     *      console.log("A local notification has been received: " + JSON.stringify(userData));
     * });
     *
     * Cocoon.Notification.Local.init();
     *
     * var notification = {
     *  message : "Hi, I am a notification",
     *  soundEnabled : true,
     *  badgeNumber : 0,
     *  userData : {"key1" : "value1", "key2": "value2"},
     *  contentBody : "",
     *  contentTitle : "",
     *  date : new Date().valueOf() + 1000
     * };
     *   
     * Cocoon.Notification.Local.send(notification);
     */
    Cocoon.define("Cocoon.Notification", function(extension) {
        "use strict";

        function NotificationService(serviceName) {
        	this.serviceName = serviceName;
        	this.signal = new Cocoon.Signal();
        	var me = this;
        	document.addEventListener('deviceready', function(){
                Cocoon.exec(me.serviceName, "setListener", [], function(data) {
                	me.signal.emit(data[0], null, data.slice(1));
            	});
        	});

        };

        extension.NotificationService = NotificationService;
        var proto = NotificationService.prototype;

        /**
         * Starts the Notification Service. This will make the system to initialize the InApp callbacks will start to be received after calling this method.
         * Because of this, you should have set your event handler before calling this method, so you won't lose any callback.
         * @memberof Cocoon.InApp
         * @function initialize
         * @param {Cocoon.InApp.Settings} params The initialization params.
         * @param {function} callback The callback function.It receives the following parameters:
         * - Error.
         * @example
         * Cocoon.InApp.initialize({
         *     autofinish: true
         * }, function(error){
         *      if(error){
         *           console.log("Error: " + error);
         *      }
         * });
         */
        proto.initialize = function(params, callback) {
            Cocoon.exec(this.serviceName, "initialize", [params], function(data) {
                if (callback) {
                    callback(data.error);
                }
            });
        };

        /**
         * Send notification
         * @function send
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Cocoon.Notification.NotificationInfo} notification The notification to sends
         * @param {Function} callback The delivery callback function. It receives the following parameters:
         * - Error.
         */
        proto.send = function(callback) {
            Cocoon.exec(this.serviceName, 'send', [notification], callback, callback);
        }

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
        }

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
        }

        /**
         * Cancels the local notification with Id provided
         * @function cancel
         * @memberOf Cocoon.Notification.NotificationService
         * @param {string}  The notification id
         */
        proto.cancel = function(notificationId) {
            Cocoon.exec(this.serviceName, 'cancel', [notificationId]);
        }

        /**
         * Cancels all the pending notifications
         * @function cancelAllNotifications
         * @memberOf Cocoon.Notification.NotificationService
         */
        proto.cancelAllNotifications = function() {
            Cocoon.exec(this.serviceName, 'cancelAll', []);
        }

        /**
         * (iOS only) Sets the badge number for this application.
         * @function setBadgeNumber
         * @memberOf Cocoon.Notification.NotificationService
         * @param {number} badgeNumber The badge number
         */
        proto.setBadgeNumber = function(badgeNumber) {
            Cocoon.exec(this.serviceName, 'setBadgeNumber', [badgeNumber]);
        }

        /**
         * (iOS only) Gets the current badge number.
         * @function getBadgeNumber
         * @memberOf Cocoon.Notification.NotificationService
         * @param {Function} callback The callback to get badgeNumber. It receives the following parameters:
         * - badgeNumber.
         */
        proto.getBadgeNumber = function(callback) {
            Cocoon.exec(this.serviceName, 'getBadgeNumber', [], callback);
        }

        /**
         * Allows to listen to events about the purchasing process.
         * - The callback 'start' receives a parameter the product id of the product being purchased when the purchase of a product starts.
         * - The callback 'complete' receives as parameter the {@link Cocoon.InApp.PurchaseInfo} object of the product being purchased when the purchase of a product is completed.
         * - The callback 'error' receives a parameters the product id and an error message when the purchase of a product fails.
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
        proto.on = extension.signal.expose();


        /**
         * The object that represents the information of a notification.
         * @memberof Cocoon.Notification
         * @name Cocoon.Notification.NotificationInfo
         * @property {object} Cocoon.Notification.NotificationInfo - The object itself
         * @property {string}   Cocoon.Notification.NotificationInfo.message The notification message. By default, it will be empty. 
         * @property {boolean}  Cocoon.Notification.NotificationInfo.soundEnabled A flag that indicates if the sound should be enabled for the notification. By default, it will be true. 
         * @property {number}   Cocoon.Notification.NotificationInfo.badgeNumber The number that will appear in the badge of the application icon in the home screen. By default, it will be 0. 
         * @property {object}   Cocoon.Notification.NotificationInfo.userData The JSON data to attached to the notification. By default, it will be empty. 
         * @property {string}   Cocoon.Notification.NotificationInfo.contentBody The body content to be showed in the expanded notification information. By default, it will be empty. 
         * @property {string}   Cocoon.Notification.NotificationInfo.contentTitle The title to be showed in the expanded notification information. By default, it will be empty. 
         * @property {number}   Cocoon.Notification.NotificationInfo.date Time in millisecs from 1970 when the notification will be fired. By default, it will be 1 second (1000).
         */
        extension.NotificationInfo = {
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
