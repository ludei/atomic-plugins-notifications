//
//  LDNotificationPlugin
//
//  Created by Imanol Fernandez @MortimerGoro
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


typedef void (^SettingsRegisterHandler)(UIUserNotificationSettings * result);
typedef void (^RemoteRegisterHandler)(NSError * error);

@interface LDNotificationPlugin : CDVPlugin

@property (nonatomic, strong) NSString * remoteToken;

- (void)onLocalNotification:(NSNotification*)notification;
- (void)onRemoteNotification:(NSNotification*)notification;
- (void)onDidRegisterForRemoteNotification:(NSNotification*)notification;
- (void)onDidFailToRegisterForRemoteNotification:(NSNotification*)notification;

- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)settings handler:(SettingsRegisterHandler) handler;
- (void)registerForRemoteNotifications:(RemoteRegisterHandler)handler;

@end
