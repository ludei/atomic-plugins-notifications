#import "LDNotificationParsePlugin.h"
#import <Parse/Parse.h>

static BOOL processedLaunchNotifications = NO;

@implementation LDNotificationParsePlugin
{
    BOOL _granted;
}

- (void)pluginInitialize
{
    [super pluginInitialize];
    if (!processedLaunchNotifications) {
        NSDictionary * launchOptions = [CDVAppDelegate launchOptions];
        if (launchOptions) {
            NSObject * remoteNotification = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
            if (remoteNotification) {
                [self.pendingRemoteNotifications addObject:remoteNotification];
            }
        }
        processedLaunchNotifications = YES;
    }
}

-(BOOL) isRegistered
{
    UIApplication * app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(currentUserNotificationSettings)]) {
        if (app.currentUserNotificationSettings.types == UIUserNotificationTypeNone) {
            return NO;
        }
    }
    BOOL result = _granted;
    if ([app respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        result = [app isRegisteredForRemoteNotifications];
    }
    return result;
}

- (void)processRemoteNotification:(NSDictionary*)userInfo
{
    [PFPush handlePush:userInfo];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [super fillApplicationState:dic];
    [self notifyNotificationReceived:dic];
}

-(void) initialize:(CDVInvokedUrlCommand *) command
{
    NSDictionary * params = [command argumentAtIndex:0 withDefault:@{} andClass:[NSDictionary class]];
    NSString * appId = [params objectForKey:@"appId"];
    NSString * clientKey = [params objectForKey:@"clientKey"];
    
    if (appId.length == 0 || clientKey.length == 0) {
        CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"code":@0, @"message":@"appId or clientKey parameters not specified"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    [Parse setApplicationId:appId clientKey:clientKey];
    
    NSNumber * value = [params objectForKey:@"register"];
    BOOL autoregister = value ? value.boolValue : YES;
    BOOL granted = [self isRegistered];
    if (autoregister && !granted) {
        [self register:command];
    }
    else {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:granted] callbackId:command.callbackId];
    }
    [super start];
}

-(void) register:(CDVInvokedUrlCommand *) command
{
    if ([self isRegistered]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        return;
    }
    
    [self registerForRemoteNotifications:^(NSData * deviceToken, NSError *error) {
        if (error) {
            _granted = NO;
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self errorToDic:error]] callbackId:command.callbackId];
        }
        else {
            // Store the deviceToken in the current installation and save it to Parse.
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation setDeviceTokenFromData:deviceToken];
            [currentInstallation saveInBackground];
            _granted = YES;
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        }
    }];
}

-(void) unregister:(CDVInvokedUrlCommand *) command
{
    UIApplication * app = [UIApplication sharedApplication];
    [app unregisterForRemoteNotifications];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


-(void) isRegistered:(CDVInvokedUrlCommand *) command
{
    BOOL result = [self isRegistered];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:result] callbackId:command.callbackId];
}


-(void) send:(CDVInvokedUrlCommand *) command
{
    //NSString * identifier = [command argumentAtIndex:0 withDefault:@"notId" andClass:[NSString class]];
    NSDictionary * data = [command argumentAtIndex:1 withDefault:@{} andClass:[NSDictionary class]];
    
    PFPush * notification = [[PFPush alloc] init];
    [notification setMessage:[data objectForKey:@"message"] ?: @""];
    
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    NSDictionary * userData = [data objectForKey:@"userData"];
    if (userData && [userData isKindOfClass:[NSDictionary class]]) {
        [info setValuesForKeysWithDictionary:userData];
    }
    [notification setData:info];
    
    [notification sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        }
        else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self errorToDic:error]] callbackId:command.callbackId];
        }
    }];
}

-(void) subscribe:(CDVInvokedUrlCommand *) command
{
    NSString * channel = [command argumentAtIndex:0 withDefault:@"" andClass:[NSString class]];
    if (channel.length == 0) {
        CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"code":@0, @"message":@"Invalid channel identifier"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    [PFPush subscribeToChannelInBackground:channel block:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        }
        else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self errorToDic:error]] callbackId:command.callbackId];
        }
        
    }];

}

-(void) unsubscribe:(CDVInvokedUrlCommand *) command
{
    NSString * channel = [command argumentAtIndex:0 withDefault:@"" andClass:[NSString class]];
    if (channel.length == 0) {
        CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"code":@0, @"message":@"Invalid channel identifier"}];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    [PFPush unsubscribeFromChannelInBackground:channel block:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        }
        else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self errorToDic:error]] callbackId:command.callbackId];
        }
        
    }];
    

}

-(void) fetchSubscribedChannels: (CDVInvokedUrlCommand* ) command
{
    [PFPush getSubscribedChannelsInBackgroundWithBlock:^(NSSet * _Nullable channels, NSError * _Nullable error) {
        CDVPluginResult * result;
        if (error) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[self errorToDic:error]];
        }
        else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[channels allObjects] ?: @[]];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        
    }];
}

-(void) cancel:(CDVInvokedUrlCommand *) command
{
    CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"code":@0, @"message":@"Not possible tp cancel already sent client push notifications in Parse"}];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void) cancelAllNotifications:(CDVInvokedUrlCommand *) command
{
    CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"code":@0, @"message":@"Not possible tp cancel already sent client push notifications in Parse"}];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



@end
