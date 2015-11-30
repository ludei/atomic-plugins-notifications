#import "LDNotificationPlugin.h"


#pragma mark LDAdServicePlugin Implementation

static BOOL pendingAppRegisterSettings = NO;
static BOOL pendingRemoteRegisterSettings = NO;


@implementation LDNotificationPlugin
{
    CDVInvokedUrlCommand * _notificationListener;
    NSMutableArray * _settingsRegisterHandlers;
    NSMutableArray * _remoteRegisterHandlers;
}

- (void)pluginInitialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLocalNotification:) name:CDVLocalNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRemoteNotification:) name:@"CDVDidReceiveRemoteNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidRegisterForRemoteNotification:) name:CDVRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFailToRegisterForRemoteNotification:) name:CDVRemoteNotificationError object:nil];
}

- (void)dispose
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onLocalNotification:(NSNotification*)notification
{

}

- (void)onRemoteNotification:(NSNotification*)notification
{

}

- (void)onDidRegisterForRemoteNotification:(NSNotification*)notification
{
    pendingRemoteRegisterSettings = NO;
    for (RemoteRegisterHandler handler in _remoteRegisterHandlers) {
        handler(nil);
    }
    [_remoteRegisterHandlers removeAllObjects];
}

- (void)onDidFailToRegisterForRemoteNotification:(NSNotification*)notification
{
    pendingRemoteRegisterSettings = NO;
    for (RemoteRegisterHandler handler in _remoteRegisterHandlers) {
        handler(nil);
    }
    [_remoteRegisterHandlers removeAllObjects];
}


- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)settings handler:(SettingsRegisterHandler) handler
{
    if (!pendingAppRegisterSettings) {
        pendingAppRegisterSettings = YES;
        [_settingsRegisterHandlers addObject:handler];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

- (void)registerForRemoteNotifications:(RemoteRegisterHandler)handler
{
    UIApplication * app = [UIApplication sharedApplication];
    BOOL alreadyRegistered = NO;
    if ([app respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        alreadyRegistered = [app isRegisteredForRemoteNotifications];
    }
    if (alreadyRegistered) {
        handler(nil);
        return;
    }
    
    if (!pendingRemoteRegisterSettings) {
        pendingRemoteRegisterSettings = YES;
        [_remoteRegisterHandlers addObject:handler];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

#pragma mark Common Notification API

-(void) setListener:(CDVInvokedUrlCommand*) command
{
    _notificationListener = command;
}

-(void) initialize:(CDVInvokedUrlCommand *) command
{
    
}


-(NSDictionary *) errorToDic:(NSError * ) error
{
    return @{@"code":[NSNumber numberWithInteger:error.code], @"message":error.localizedDescription?:@"Unkown error"};
}


@end
