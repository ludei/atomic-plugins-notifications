"use strict";

(function(){

    var backgroundTexture, button1Texture, button2Texture, backTexture;
    var btnRegister, btnUnregister, btnSubscribe, btnUnsubscribe, btnSend, btnCancel, btnCancelAll;

    var targetService;
    var localService;
    var pushService;
    var lastNotification;

    var container;

    var index = 0;


    function initProviders() {
        if (window.Cocoon && Cocoon.Notification) {
            localService = Cocoon.Notification.Local;
            pushService = Cocoon.Notification.Parse;


            if (localService) {
                localService.on('notification', function(userData){
                    alert('Received local notification: ' + JSON.stringify(userData));
                });

                localService.initialize({}, function(registered){
                    localService.registered = registered;
                });
            }

            if (pushService) {
                pushService.on('notification', function(userData){
                    alert('Received push notification: ' + JSON.stringify(userData));
                });

                pushService.initialize({appId: "HzEoGOQvoLgFa0vtsowsljQP4g3KBO3p6N033WZx", clientKey: "gKtKVnIg4JKAc5O5hbk8tHshAU4LDv0iEJ1VSlDO"}, function(registered, error){
                    pushService.registered = registered;
                    if (error) {
                        alert('Error initializing Parse:' + error.message);
                    }
                });
            }
        }
    }

    function showProviderSelector() {

        container.removeChildren();

        var btnTestLocal = createButton("Local Notifications", function(){
            if (!localService) {
                alert('Cocoon.Notification.Local plugin not installed');
                return;
            }
            targetService = localService;
            showControls();

        });
        var btnTestParse = createButton("Push Notifications (Parse)", function(){

            if (!pushService) {
                alert('Cocoon.Notification.Parse plugin not installed');
                return;
            }
            targetService = pushService;
            showControls();
        });

        btnTestLocal.position.set(0, -50);
        container.addChild(btnTestLocal);

        btnTestParse.position.set(0, 50);
        container.addChild(btnTestParse);
    }

    function showControls() {
        container.removeChildren();


        var push = targetService === pushService;

        //Add buttons
        btnRegister = createButton(push ? "Register For Push Notifications" : "Register for Local Notifications", function(){
            targetService.register({}, function(error){
                btnRegister.visible = !!error;
                btnUnregister.visible = !btnRegister.visible;
                if (error) {
                    alert('Error: ' + error.message);
                }
            });
        });

        btnRegister.visible = !targetService.registered;

        btnUnregister = createButton(push ? "Unregister from Push Notifications" : "Unregister from Local Notifications", function(){
            targetService.unregister(function(error){
                btnUnregister.visible = !!error;
                btnRegister.visible = !btnUnregister.visible;
                if (error) {
                    alert('Error: ' + error.message);
                }
            });
        });
        btnUnregister.visible = !!targetService.registered;

        btnSubscribe = createButton("Subscribe push channel", function(){
            targetService.subscribe("testchannel", function(error){
                btnSubscribe.visible = !!error;
                btnUnsubscribe.visible = !btnSubscribe.visible;
                if (error) {
                    alert('Error: ' + error.message);
                }
            });
        });

        btnUnsubscribe = createButton("Unsubscribe push channel", function(){
            targetService.unsubscribe("testchannel", function(error){
                btnUnsubscribe.visible = !!error;
                btnSubscribe.visible = !btnUnsubscribe.visible;
                if (error) {
                    alert('Error: ' + error.message);
                }
            });
        });


        btnSend = createButton(push ? "Send client test push notification" : "Send local notification (5 sec)", function(){

            index++;
            var notification = {
                message : "Hi, I am a notification",
                soundEnabled : true,
                badgeNumber : 1,
                userData : {"key1" : "value1", "key2": "value2", "index": index},
                contentBody : "",
                contentTitle : "",
                date : new Date().valueOf() + 5000
            };
            lastNotification = notification;
            targetService.send(notification, function(error){

                if (error) {
                    alert('Error: ' + error.message);
                }

            });
        });

        var btnResetBadge = createButton("Reset badge number", function(){
            targetService.setBadgeNumber(0, function(error){
                if (error) {
                    alert('Error: ' + error.message);
                }
            });
        });

        btnCancel = createButton("Cancel last notification", function(){

            if (lastNotification) {
                targetService.cancel(lastNotification.id);
            }

        });

        btnCancelAll = createButton("Cancel all notification", function(){
            targetService.cancelAllNotifications();
        });


        var btnBack = createBackButton(function(){
            showProviderSelector();
        });

        if (targetService === pushService) {
            btnRegister.position.set(0, -150);
            container.addChild(btnRegister);
            btnUnregister.position.set(0, -150);
            container.addChild(btnUnregister);

            btnSubscribe.position.set(0, -50);
            container.addChild(btnSubscribe);
            btnUnsubscribe.position.set(0, -50);
            btnUnsubscribe.visible = false;
            container.addChild(btnUnsubscribe);

            btnSend.position.set(0, 50);
            container.addChild(btnSend);

            btnResetBadge.position.set(0, 150);
            container.addChild(btnResetBadge);

            targetService.fetchSubscribedChannels(function(channels, error) {
                var subscribed = !error && channels && channels.length > 0;
                btnSubscribe.visible = !subscribed;
                btnUnsubscribe.visible = subscribed;
            });
        }
        else {
            btnRegister.position.set(0, -250);
            container.addChild(btnRegister);
            btnUnregister.position.set(0, -250);
            container.addChild(btnUnregister);

            btnSend.position.set(0, -150);
            container.addChild(btnSend);

            btnCancel.position.set(0, -50);
            container.addChild(btnCancel);

            btnCancelAll.position.set(0, 50);
            container.addChild(btnCancelAll);

            btnResetBadge.position.set(0, 150);
            container.addChild(btnResetBadge);
        }

        btnBack.position.set(0, 300);
        container.addChild(btnBack);


        targetService.isRegistered(function(granted){
            btnUnregister.visible = !!granted;
            btnRegister.visible = !granted;
        });

    }

    function initDemo(){

        initProviders();

        var renderer = PIXI.autoDetectRenderer(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.view);

        var W = 800;
        var H = 600;

        //load resources
        backgroundTexture = PIXI.Texture.fromImage('./images/background.jpg');
        button1Texture = PIXI.Texture.fromImage('./images/button1.png');
        button2Texture = PIXI.Texture.fromImage('./images/button2.png');
        backTexture = PIXI.Texture.fromImage('./images/back.png');

        var stage = new PIXI.Container();
        stage.interactive = true;

        //Add background
        var background = new PIXI.Sprite(backgroundTexture);
        background.width = renderer.width;
        background.height = renderer.height;
        stage.addChild(background);

        var scale = Math.min(renderer.width/W, renderer.height/H);
        container = new PIXI.Container();
        container.scale.set(scale, scale);
        container.position.set(renderer.width/2, renderer.height/2);
        stage.addChild(container);

        showProviderSelector();
        // start animating
        animate();
        function animate() {
            requestAnimationFrame(animate);
            renderer.render(stage);
        }
    }

    function createButton(text, callback) {

        var button = new PIXI.Sprite(button1Texture);
        button.anchor.set(0.5, 0.5);
        button.interactive = true;
        button.addChild(createText(text));

        button.mousedown = button.touchstart = function(){
            this.texture = button2Texture;
            callback();
        };

        button.mouseup = button.touchend = function(){
            this.texture = button1Texture;
        };

        return button;
    }

    function createBackButton(callback) {
        var button = new PIXI.Sprite(backTexture);
        button.anchor.set(0.5, 0.5);
        button.interactive = true;
        button.addChild(createText("Back"));
        button.mousedown = button.touchstart = function(){
            callback();
        };
        return button;
    }

    function createText(text, size, fill){
        size = size || 25;
        fill = fill || "#ffffff";
        var txt = new PIXI.Text(text, {
            fill: fill,
            font: size + "px Arial"
        });
        txt.anchor.set(0.5, 0.5);

        return txt;
    }

    if (window.cordova) {
        document.addEventListener("deviceready", initDemo);
    }
    else {
        window.onload = initDemo;
    }


})();







