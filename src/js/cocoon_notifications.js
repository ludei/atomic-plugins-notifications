(function(){

    if (!window.Cocoon && window.cordova && typeof require !== 'undefined') {
        cordova.require('cocoon-plugin-common.Cocoon');
    }
    var Cocoon = window.Cocoon;

    /**
    * @fileOverview
    <h2>About Atomic Plugins</h2>
    <p>Atomic Plugins provide an elegant and minimalist API and are designed with portability in mind from the beginning. Framework dependencies are avoided by design so the plugins can run on any platform and can be integrated with any app framework or game engine.
    <br/> <p>You can contribute and help to create more awesome plugins. </p>
    <h2>Atomic Plugins for Notifications</h2>
    <p>This <a src="https://github.com/ludei/atomic-plugins-notifications">repository</a> contains a Notifications API designed using the Atomic Plugins paradigm. The API is already available in many languagues and we plan to add more in the future.</p>
    <h3>Setup your project</h3>
    <p>Releases are deployed to Cordova Plugin Registry. 
    You only have to install the desired plugins using Cordova CLI and <a href="https://cocoon.io"/>Cocoon Cloud service</a>.</p>
    <ul>
    <code>cordova plugin add cocoon-plugin-notifications-android-local</code><br/>
    <code>cordova plugin add cocoon-plugin-notifications-android-parse</code><br/>
    <code>cordova plugin add cocoon-plugin-notifications-ios-local</code><br/>
    <code>cordova plugin add cocoon-plugin-notifications-ios-parse</code><br/>
    </ul>
    <h3>Documentation</h3>
    <p>In this section you will find all the documentation you need for using this plugin in your Cordova project. 
    Select the specific namespace below to open the relevant documentation section:</p>
    <ul>
    <li><a href="http://ludei.github.io/atomic-plugins-docs/dist/doc/js/Cocoon.Notifications.html">Notifications</a></li>
    <li><a href="http://ludei.github.io/atomic-plugins-docs/dist/doc/js/Cocoon.Notifications.Local.html">Local Notifications</a></li>
    <li><a href="http://ludei.github.io/atomic-plugins-docs/dist/doc/js/Cocoon.Notifications.Parse.html">Parse Notifications</a></li>
    </ul>
    * @version 1.0
    */

    /**
     * This namespace represents the Cocoon Notification extension for local and remote notifications.
     * @namespace Cocoon.Notification
     *
     * @example 
     * //Set up notification listener
     * Cocoon.Notification.Local.on("notification", function(userData){
     *      console.log("A local notification has been received: " + JSON.stringify(userData));
     * });
     *
     * Cocoon.Notification.Local.initialize(); //ready to start receiving notification callbacks
     *
     * // Initialize the service. Ready to start receiving notification callbacks
     * // You can make the service to be registered automatically after calling initialize passing a {register: false} paramter. It may show a Dialog to request user permissions.
     * // You can disable autoregister with {register: false} params and call Cocoon.Notification.Local.register() manually to control when the permissions dialog is shown.     *
     *
     * Cocoon.Notification.Local.initialize({}, function(registered) {
     *  if (!registered) {
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

        //clean unwanted "OK" result param on android
        function successFunc(callback) {
            return function() {
                if (callback) {
                    callback();
                }
            };
        }

        /**
         * Starts the Notification Service. The notification callbacks will start to be received after calling this method.
         * Because of this, you should have set your event handler before calling this method, so you won't lose any callback.
         * The service can be automatically registered after the initialization. This may show a Dialog to request user permissions.
         * You can disable autoregister with {register: false} params and call Cocoon.Notification.Local.register() manually to control when the permissions dialog is shown.
         * By default the register paramter is set to true.
         * @memberof Cocoon.Notification
         * @function initialize
         * @param {Object} params. Service dependant params
         * @param {Function} callback The callback function. It receives the following parameters:
         * - Registered: True if the devices is already registered to receive notifications
         * - Error.
         */
        proto.initialize = function(params, callback) {
            var me = this;
            Cocoon.exec(this.serviceName, "setListener", [], function(data) {
                me.signal.emit('notification', null, [data]);
            });
            Cocoon.exec(this.serviceName, 'initialize', [params], successFunc(callback), function(error){
                if (callback) {
                    callback(false, error);
                }
            });
        };


        /**
         * Checks if user has permission to receive notifications
         * @function canReceiveNotifications
         * @memberOf Cocoon.Notification
         * @param {Function} callback The callback function. It receives the following parameters:
         * - granted {Boolean} True if the user has permission to receive notifications
         */
        proto.isRegistered = function(callback) {
            Cocoon.exec(this.serviceName, "isRegistered", [], callback, callback);
        };

        /**
         * Registers the application to be able to receive push notifications. In some systems like iOS it shows a dialog to request user permission.
         * @function register
         * @memberOf Cocoon.Notification
         * @param {Object} params
         * @param {Function} callback The callback function. It receives the following parameters:
         * - Error.
         */
        proto.register = function(params, callback) {
            Cocoon.exec(this.serviceName, 'register', [params], successFunc(callback), callback);
        };

        /**
        * Unregisters the application from receiving push notifications
         * @function unregister
         * @memberOf Cocoon.Notification
         * @param {Object} params
         * @param {Function} callback The callback function. It receives the following parameters:
         * - Error.
         */
        proto.unregister = function(callback) {
            Cocoon.exec(this.serviceName, 'unregister', [], successFunc(callback), callback);
        };


        /**
         * Send notification
         * @function send
         * @memberOf Cocoon.Notification
         * @param {Cocoon.Notification.NotificationInfo} notification The notification to sends
         * @param {Function} callback The delivery callback function. It receives the following parameters:
         * - Error.
         */
        proto.send = function(notification, callback) {
            var identifier = this.idIndex++ + '';
            notification.id = identifier;
            Cocoon.exec(this.serviceName, 'send', [notification], successFunc(callback), callback);
            return identifier;
        };

        /**
         * Subscribes to a channel in order to receive notifications targeted to that channel.
         * Valid for notification services that support specific channels (e.g. Parse).
         * @function subscribe
         * @memberOf Cocoon.Notification
         * @param {string} channel The channel id
         * @param {Function} callback The subscribe succeeded callback function. It receives the following parameters:
         * - Error.
         */
        proto.subscribe = function(channel, callback) {
            Cocoon.exec(this.serviceName, 'subscribe', [channel], successFunc(callback), callback);
        };

        /**
         * Unsubscribes from a channel in order to stop receiving notifications targeted to it.
         * Valid for notification services that support specific channels (e.g. Parse).
         * @function unsubscribe
         * @memberOf Cocoon.Notification
         * @param {string} channel The channel id
         * @param {Function} callback The unsubscribe succeeded callback function. It receives the following parameters:
         * - Error.
         */
        proto.unsubscribe = function(channel, callback) {
            Cocoon.exec(this.serviceName, 'unsubscribe', [channel], successFunc(callback), callback);
        };

        /**
         * Asynchronously get all the channels that this device is subscribed to.
         * Valid for notification services that support specific channels (e.g. Parse).
         * @function fetchSubscribedChannels
         * @memberOf Cocoon.Notification
         * @param {Function} callback Callback function to get the channel list. It receives the following parameters:
         * - channels {array} the channels that this device is subscribed to
         * - error.
         */
        proto.fetchSubscribedChannels = function(callback) {
            Cocoon.exec(this.serviceName, 'fetchSubscribedChannels', [], callback, function(error){
                if (callback) {
                    callback([], error);
                }
            });
        };

        /**
         * Cancels the local notification with Id provided
         * @function cancel
         * @memberOf Cocoon.Notification
         * @param {string}  The notification id
         */
        proto.cancel = function(notificationId) {
            Cocoon.exec(this.serviceName, 'cancel', [notificationId]);
        };

        /**
         * Cancels all the pending notifications
         * @function cancelAllNotifications
         * @memberOf Cocoon.Notification
         */
        proto.cancelAllNotifications = function() {
            Cocoon.exec(this.serviceName, 'cancelAllNotifications', []);
        };

        /**
         * (iOS only) Sets the badge number for this application.
         * @function setBadgeNumber
         * @memberOf Cocoon.Notification
         * @param {number} badgeNumber The badge number
         */
        proto.setBadgeNumber = function(badgeNumber) {
            Cocoon.exec(this.serviceName, 'setBadgeNumber', [badgeNumber]);
        };

        /**
         * (iOS only) Gets the current badge number.
         * @function getBadgeNumber
         * @memberOf Cocoon.Notification
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
