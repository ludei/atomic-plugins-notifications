#import "LDNotificationLocalPlugin.h"

static BOOL processedLaunchNotifications = NO;

@implementation LDNotificationLocalPlugin
{
    BOOL _granted;
}


- (void)pluginInitialize
{
    [super pluginInitialize];
    _scheduledNotifications = [[NSMutableDictionary alloc] init];
    
    if (!processedLaunchNotifications) {
        NSDictionary * launchOptions = [CDVAppDelegate launchOptions];
        if (launchOptions) {
            UILocalNotification * localNotification = [launchOptions objectForKey:@"UIApplicationLaunchOptionsLocalNotificationKey"];
            if (localNotification) {
                [self.pendingLocalNotifications addObject:localNotification];
            }
        }
        processedLaunchNotifications = YES;
    }
}

-(BOOL) isRegistered
{
    UIApplication * app = [UIApplication sharedApplication];
    BOOL result = _granted;
    if ([app respondsToSelector:@selector(currentUserNotificationSettings)]) {
        result = app.currentUserNotificationSettings.types != UIUserNotificationTypeNone;
    }
    return result;
}

- (void)processLocalNotification:(UILocalNotification*)notification
{
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithDictionary: notification.userInfo ?: @{}];
    NSString * identifier = [userInfo objectForKey:COCOON_NOTIFICATION_ID];
    if (identifier && [identifier isKindOfClass:[NSString class]]) {
        [_scheduledNotifications removeObjectForKey:identifier];
        [userInfo removeObjectForKey:COCOON_NOTIFICATION_ID];
    }
    [super fillApplicationState: userInfo];
    [self notifyNotificationReceived:userInfo];
}

-(void) initialize:(CDVInvokedUrlCommand *) command
{
    NSDictionary * params = [command argumentAtIndex:0 withDefault:@{} andClass:[NSDictionary class]];
    NSNumber * value = [params objectForKey:@"register"];
    BOOL autoregister = value ? value.boolValue : YES;
    BOOL granted = [self isRegistered];
    if (autoregister && !granted) {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings * settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [self registerUserNotificationSettings:settings handler:^(UIUserNotificationSettings *result) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:result.types != UIUserNotificationTypeNone] callbackId:command.callbackId];
        }];
    }
    else {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:granted] callbackId:command.callbackId];
    }
    [super start];
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
    BOOL result = [self isRegistered];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:result] callbackId:command.callbackId];
}


-(void) send:(CDVInvokedUrlCommand *) command
{
    NSDictionary * data = [command argumentAtIndex:0 withDefault:@{} andClass:[NSDictionary class]];
    NSString * identifier = [data objectForKey:@"id"] ?: @"notId";
    
    UILocalNotification * notification = [[UILocalNotification alloc] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = [data objectForKey:@"message"] ?: @"";
    if ([notification respondsToSelector:@selector(alertTitle)]) {
        notification.alertTitle = [data objectForKey:@"title"] ?: @"";
    }
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
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) subscribe:(CDVInvokedUrlCommand *) command
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) unsubscribe:(CDVInvokedUrlCommand *) command
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) fetchSubscribedChannels: (CDVInvokedUrlCommand* ) command
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]] callbackId:command.callbackId];
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
