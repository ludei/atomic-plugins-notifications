Atomic Plugins for Notifications
===============================

This repo contains Notifications APIs designed using the [Atomic Plugins paradigm](#about-atomic-plugins). Integrate Notifications services in your app easily and take advantage of all the features provided: elegant API, flexible solution that works across multiple platforms, single API for different Notifications Services and more. 
 
Currently there are 2 notification services implemented:

* Local Notifications
* Parse Push Notification

You can contribute and help to create more awesome plugins.

##About Atomic Plugins

Atomic Plugins provide an elegant and minimalist API and are designed with portability in mind from the beginning. Framework dependencies are avoided by design so the plugins can run on any platform and can be integrated with any app framework or game engine. 

#Provided APIs

  * [JavaScript API](#javascript-api)
  * [API Reference](#api-reference)
  * [Introduction](#introduction)
  * [Setup your project](#setup-your-project)
  * [Example](#example-1)

##JavaScript API:

###API Reference

See [API Documentation](http://ludei.github.io/atomic-plugins-docs/dist/doc/js/Cocoon.Notification.html)

###Introduction 

Cocoon.Notification class provides an easy to use Notification API that can be used with different Notification Services: Local and [`Parse`](http://www.parse.com).

###Setup your project

Releases are deployed to Cordova Plugin Registry. You only have to install the desired plugins using Cordova CLI, CocoonJS CLI or Ludei's Cocoon.io Cloud Server.

    cordova plugin add cocoon-plugin-notifications-ios-local;
    cordova plugin add cocoon-plugin-notifications-android-local;
    cordova plugin add cocoon-plugin-notifications-ios-parse;
    cordova plugin add cocoon-plugin-notifications-android-parse;

The following JavaScript file is included automatically:

[`cocoon_notifications.js`](src/js/cocoon_notifications.js)

And, depending on the notifications service used, also: 

[`cocoon_notifications_local.js`](src/js/cocoon_notifications_local.js)
[`cocoon_notifications_parse.js`](src/js/cocoon_notifications_parse.js)

###Example

	//Set up notification listener
	Cocoon.Notification.Local.on("notification", function(userData){
	    console.log("A local notification has been received: " + JSON.stringify(userData));
	});

	Cocoon.Notification.Local.initialize(); //ready to start receiving notification callbacks

	// Initialize the service. Ready to start receiving notification callbacks
	// Auto register the application to receive notifications. It may show a Dialog to request user permissions.
	// You can disable autoregister witht {register:false} params and call Cocoon.Notification.Local.register() manually

	Cocoon.Notification.Local.initialize({}, function(registered) {
	if (!registered) {
	    alert('Notifications disabled by user')
	}
	else {
	    sendNotification(); 
	}
	})

	function sendNotification() {
	   var notification = {
	    message : "Hi, I am a notification",
	    soundEnabled : true,
	    badgeNumber : 0,
	    userData : {"key1" : "value1", "key2": "value2"},
	    contentBody : "",
	    contentTitle : "",
	    date : new Date().valueOf() + 1000
	   };

	   Cocoon.Notification.Local.send(notification);
	}

#License

Mozilla Public License, version 2.0

Copyright (c) 2015 Ludei 

See [`MPL 2.0 License`](LICENSE)

