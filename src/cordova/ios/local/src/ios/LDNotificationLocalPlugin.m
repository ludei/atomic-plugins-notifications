#import "LDNotificationLocalPlugin.h"


@implementation LDNotificationLocalPlugin
{
    BOOL _granted;
}


- (void)pluginInitialize
{
    [super pluginInitialize];
    _scheduledNotifications = [[NSMutableDictionary alloc] init];
}

- (void)processLocalNotification:(UILocalNotification*)notification
{
    NSDictionary * userInfo = notification.userInfo ?: @{};
    NSString * identifier = [userInfo objectForKey:COCOON_NOTIFICATION_ID];
    if (identifier && [identifier isKindOfClass:[NSString class]]) {
        [_scheduledNotifications removeObjectForKey:identifier];
        NSMutableDictionary * tmp = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        [tmp removeObjectForKey:COCOON_NOTIFICATION_ID];
        userInfo = tmp;
    }
    [self notifyNotificationReceived:userInfo];
}

-(void) register:(CDVInvokedUrlCommand *) command
{
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings * settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [self registerUserNotificationSettings:settings handler:^(UIUserNotificationSettings *result) {
        
        CDVPluginResult * pluginResult;
        if (result.types != UIUserNotificationTypeNone) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            _granted = YES;
        }
        else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"code":@0, @"message":@"Access denied by user"}];
            _granted = NO;
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
    }];
}

-(void) unregister:(CDVInvokedUrlCommand *) command
{
    UIUserNotificationType types = UIUserNotificationTypeNone;
    UIUserNotificationSettings * settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [self registerUserNotificationSettings:settings handler:^(UIUserNotificationSettings *result) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    }];
}

-(void) isRegistered:(CDVInvokedUrlCommand *) command
{
    UIApplication * app = [UIApplication sharedApplication];
    BOOL result = _granted;
    if ([app respondsToSelector:@selector(currentUserNotificationSettings)]) {
        result = app.currentUserNotificationSettings != UIUserNotificationTypeNone;
    }
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:result] callbackId:command.callbackId];
}


-(void) send:(CDVInvokedUrlCommand *) command
{
    NSString * identifier = [command argumentAtIndex:0 withDefault:@"notId" andClass:[NSString class]];
    NSDictionary * data = [command argumentAtIndex:1 withDefault:@{} andClass:[NSDictionary class]];
    
    UILocalNotification * notification = [[UILocalNotification alloc] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = [data objectForKey:@"message"] ?: @"";
    notification.alertTitle = [data objectForKey:@"title"] ?: @"";
    NSNumber * soundEnabled = [data objectForKey:@"soundEnabled"];
    if (soundEnabled && [soundEnabled isKindOfClass:[NSNumber class]]) {
        notification.soundName = soundEnabled.boolValue ? UILocalNotificationDefaultSoundName : nil;
    }
    else {
        notification.soundName = UILocalNotificationDefaultSoundName; //default value
    }
    NSNumber * badge = [data objectForKey:@"badgeNumber"];
    if (badge && [badge isKindOfClass:[NSNumber class]]) {
        notification.applicationIconBadgeNumber = badge.integerValue;
    }
    
    NSNumber * date = [data objectForKey:@"date"];
    if (date && [date isKindOfClass:[NSNumber class]]) {
         notification.fireDate = [NSDate dateWithTimeIntervalSince1970:date.doubleValue/1000.0];
    }
    else {
        notification.fireDate = [NSDate.date dateByAddingTimeInterval:1.0];
    }
    
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    NSDictionary * userData = [data objectForKey:@"userData"];
    if (userData && [userData isKindOfClass:[NSDictionary class]]) {
        [info setValuesForKeysWithDictionary:userData];
    }

    [info setObject:identifier forKey:COCOON_NOTIFICATION_ID];
    notification.userInfo = info;
    
    [_scheduledNotifications setObject:notification forKey:identifier];
    if (notification.fireDate) {
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    else {
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

-(void) subscribe:(CDVInvokedUrlCommand *) command
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) unsubscribe:(CDVInvokedUrlCommand *) command
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) cancel:(CDVInvokedUrlCommand *) command
{
    NSString * identifier = [command argumentAtIndex:0 withDefault:@"notId" andClass:[NSString class]];
    UILocalNotification * localNotification = [_scheduledNotifications objectForKey:identifier];
    if (localNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
        [_scheduledNotifications removeObjectForKey:identifier];
    }
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) cancelAllNotifications:(CDVInvokedUrlCommand *) command
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}



@end
