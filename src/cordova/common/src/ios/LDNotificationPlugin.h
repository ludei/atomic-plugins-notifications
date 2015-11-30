//
//  LDNotificationPlugin
//
//  Created by Imanol Fernandez @MortimerGoro
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>


typedef void (^SettingsRegisterHandler)(UIUserNotificationSettings * result);
typedef void (^RemoteRegisterHandler)(NSError * error);
#define COCOON_NOTIFICATION_ID @"CocoonNotificationId"

@interface LDNotificationPlugin : CDVPlugin

@property (nonatomic, assign) BOOL ready;
@property (nonatomic, strong) NSString * remoteToken;

- (void)processLocalNotification:(UILocalNotification*)notification;
- (void)processRemoteNotification:(NSNotification*)notification;
- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)settings handler:(SettingsRegisterHandler) handler;
- (void)registerForRemoteNotifications:(RemoteRegisterHandler)handler;
- (void)notifyNotificationReceived:(NSDictionary* ) userData;

@end




@interface CDVAppDelegate (SwizzledMethods)

- (void) cdv_notification_rebroadcastApplication:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification;

- (void) cdv_notification_rebroadcastApplication:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;

- (void) cdv_notification_rebroadcastApplication:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;

- (void) cdv_notification_rebroadcastApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *) userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;

- (void) cdv_notification_rebroadcastApplication:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *) settings;

+ (UILocalNotification*) localLaunchNotification;

@end
