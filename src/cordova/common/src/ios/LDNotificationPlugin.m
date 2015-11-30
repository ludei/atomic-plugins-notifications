#import "LDNotificationPlugin.h"


#pragma mark LDAdServicePlugin Implementation

static BOOL pendingAppRegisterSettings = NO;
static BOOL pendingRemoteRegisterSettings = NO;
static BOOL processedLaunchNotifications = NO;


@implementation LDNotificationPlugin
{
    CDVInvokedUrlCommand * _notificationListener;
    NSMutableArray * _settingsRegisterHandlers;
    NSMutableArray * _remoteRegisterHandlers;
    NSMutableArray * _pendingLocalNotifications; //stored notifications until the user has set up the notification listeners in JS
    NSMutableArray * _pendingRemoteNotifications;
}

- (void)pluginInitialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLocalNotification:) name:@"LDDidReceiveLocalNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRemoteNotification:) name:@"LDDidReceiveRemoteNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidRegisterUserNotificationSettings:) name:@"LDDidRegisterUserNotificationSettings" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidRegisterForRemoteNotification:) name:@"LDDidRegisterForRemoteNotificationsWithDeviceToken" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFailToRegisterForRemoteNotification:) name:@"LDDidFailToRegisterForRemoteNotificationsWithError" object:nil];
    
    _settingsRegisterHandlers = [[NSMutableArray alloc] init];
    _remoteRegisterHandlers = [[NSMutableArray alloc] init];
    _pendingLocalNotifications = [[NSMutableArray alloc] init];
    _pendingRemoteNotifications = [[NSMutableArray alloc] init];
    
    UILocalNotification * launchNotification = [CDVAppDelegate localLaunchNotification];
    if (launchNotification && !processedLaunchNotifications) {
        [_pendingLocalNotifications addObject:launchNotification];
        processedLaunchNotifications = YES;
    }
}

- (void)dispose
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)processLocalNotification:(NSNotification*)notification
{
    //Overridden in derived classes
}

- (void)processRemoteNotification:(NSNotification*)notification
{
    //Overridden in derived classes
}

- (void)onLocalNotification:(NSNotification*)notification
{
    if (_ready) {
        [self processLocalNotification:notification.object];
    }
    else {
        [_pendingLocalNotifications addObject:notification];
    }
}

- (void)onRemoteNotification:(NSNotification*)notification
{
    if (_ready) {
        [self processRemoteNotification:notification];
    }
    else {
        [_pendingRemoteNotifications addObject:notification];
    }
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

- (void) onDidRegisterUserNotificationSettings:(NSNotification*) notification
{
    UIUserNotificationSettings * settings = notification.object;
    pendingAppRegisterSettings = NO;
    for (SettingsRegisterHandler handler in _settingsRegisterHandlers) {
        handler(settings);
    }
    [_settingsRegisterHandlers removeAllObjects];
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

- (void)notifyNotificationReceived:(NSDictionary* ) userData
{
    if (_notificationListener) {
        CDVPluginResult * result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userData ?: @{}];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:_notificationListener.callbackId];
    }
    
}

#pragma mark Common Notification API

-(void) setListener:(CDVInvokedUrlCommand*) command
{
    _notificationListener = command;
}


-(void) initialize:(CDVInvokedUrlCommand*) command
{
    _ready = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    for (UILocalNotification * notification in _pendingLocalNotifications) {
        [self processLocalNotification:notification];
    }
    for (NSNotification * notification in _pendingRemoteNotifications) {
        [self processRemoteNotification:notification];
    }
    [_pendingLocalNotifications removeAllObjects];
    [_pendingRemoteNotifications removeAllObjects];
}


-(void) setBadgeNumber:(CDVInvokedUrlCommand*) command
{
    NSNumber * value = [command argumentAtIndex:0 withDefault:@0 andClass:[NSNumber class]];
    UIApplication * app = [UIApplication sharedApplication];
    
    if ([app respondsToSelector:@selector(currentUserNotificationSettings)]) {
        if (app.currentUserNotificationSettings.types & UIUserNotificationTypeBadge) {
            app.applicationIconBadgeNumber = value.integerValue;
        }
        else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsDictionary:@{@"code":@0, @"message":@"access denied for UIUserNotificationTypeBadge"}]
                                        callbackId:command.callbackId];
        }
        
    }
    else {
        app.applicationIconBadgeNumber = value.integerValue;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

-(void) getBadgeNumber:(CDVInvokedUrlCommand*) command
{
    NSInteger value = [UIApplication sharedApplication].applicationIconBadgeNumber;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSInteger:value] callbackId:command.callbackId];
}



-(NSDictionary *) errorToDic:(NSError * ) error
{
    return @{@"code":[NSNumber numberWithInteger:error.code], @"message":error.localizedDescription?:@"Unkown error"};
}


@end



#import <objc/runtime.h>

#pragma mark SwizzledMethods

// Return a NSArray<Class> containing all subclasses of a Class
NSArray* ClassGetSubclasses(Class parentClass)
{
    int numClasses = objc_getClassList(nil, 0);
    Class* classes = nil;
    
    classes = (Class*)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray* result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        
        Class superClass = classes[i];
        do {
            superClass = class_getSuperclass(superClass);
        }
        while(superClass && superClass != parentClass);
        
        if (superClass == nil) {
            continue;
        }
        
        [result addObject:classes[i]];
    }
    
    free(classes);
    
    return result;
}

// Replace or Exchange method implementations
// Return YES if method was exchanged, NO if replaced
BOOL MethodSwizzle(Class clazz, SEL originalSelector, SEL overrideSelector)
{
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method overrideMethod = class_getInstanceMethod(clazz, overrideSelector);
    
    // try to add, if it does not exist, replace
    if (class_addMethod(clazz, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(clazz, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    // add failed, so we exchange
    else {
        method_exchangeImplementations(originalMethod, overrideMethod);
        return YES;
    }
    
    return NO;
}

// Helper to return the Class to swizzle
// We need to swizzle the subclass (if available) of CDVAppDelegate
Class ClassToSwizzle() {
    Class clazz = [CDVAppDelegate class];
    
    NSArray* subClazz = ClassGetSubclasses(clazz);
    if ([subClazz count] > 0) {
        clazz = [subClazz objectAtIndex:0];
    }
    
    return clazz;
}


#pragma mark Global Variables

static BOOL ldLocalNotifSelExchanged = NO;
static BOOL ldRemoteNotifSelExchanged = NO;
static BOOL ldRemoteNotifErrorSelExchanged = NO;
static BOOL ldRemoteNotifReceiveSelExchanged = NO;
static BOOL ldDidRegisterUserNotificationSettings = NO;
static UILocalNotification * ldLaunchLocalNotification = nil;


#pragma mark CDVAppDelegate (SwizzledMethods)

@implementation CDVAppDelegate (SwizzledMethods)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = ClassToSwizzle();
        
        ldLocalNotifSelExchanged = MethodSwizzle(clazz, @selector(application:didReceiveLocalNotification:), @selector(cdv_notification_rebroadcastApplication:didReceiveLocalNotification:));
        ldRemoteNotifSelExchanged = MethodSwizzle(clazz, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), @selector(cdv_notification_rebroadcastApplication:didRegisterForRemoteNotificationsWithDeviceToken:));
        ldRemoteNotifErrorSelExchanged = MethodSwizzle(clazz, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), @selector(cdv_notification_rebroadcastApplication:didFailToRegisterForRemoteNotificationsWithError:));
        ldRemoteNotifReceiveSelExchanged = MethodSwizzle(clazz, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:), @selector(cdv_notification_rebroadcastApplication:didReceiveRemoteNotification:fetchCompletionHandler:));
        ldDidRegisterUserNotificationSettings = MethodSwizzle(clazz, @selector(application:didRegisterUserNotificationSettings:), @selector(cdv_notification_rebroadcastApplication:didRegisterUserNotificationSettings:));
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchNotificationChecker:) name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
    
}

+ (void)launchNotificationChecker:(NSNotification *)notification
{
    NSDictionary *launchOptions = [notification userInfo] ;
    ldLaunchLocalNotification = [launchOptions objectForKey: @"UIApplicationLaunchOptionsLocalNotificationKey"];
}

- (void) cdv_notification_rebroadcastApplication:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    // re-post ( broadcast )
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LDDidReceiveLocalNotification" object:notification];
    
    // if method was exchanged through method_exchangeImplementations, we call ourselves (no, it's not a recursion)
    if (ldLocalNotifSelExchanged) {
        [self cdv_notification_rebroadcastApplication:application didReceiveLocalNotification:notification];
    }
}

- (void) cdv_notification_rebroadcastApplication:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
{
    // re-post ( broadcast )
    NSString* token = [[[[deviceToken description]
                         stringByReplacingOccurrencesOfString:@"<" withString:@""]
                        stringByReplacingOccurrencesOfString:@">" withString:@""]
                       stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LDDidRegisterForRemoteNotificationsWithDeviceToken" object:token];
    
    // if method was exchanged through method_exchangeImplementations, we call ourselves (no, it's not a recursion)
    if (ldRemoteNotifSelExchanged) {
        [self cdv_notification_rebroadcastApplication:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void) cdv_notification_rebroadcastApplication:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;
{
    // re-post ( broadcast )
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LDDidFailToRegisterForRemoteNotificationsWithError" object:error];
    
    // if method was exchanged through method_exchangeImplementations, we call ourselves (no, it's not a recursion)
    if (ldRemoteNotifErrorSelExchanged) {
        [self cdv_notification_rebroadcastApplication:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void) cdv_notification_rebroadcastApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *) userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    
    // re-post ( broadcast )
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LDDidReceiveRemoteNotification" object:userInfo];
    
    // if method was exchanged through method_exchangeImplementations, we call ourselves (no, it's not a recursion)
    if (ldRemoteNotifReceiveSelExchanged) {
        [self cdv_notification_rebroadcastApplication:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:handler];
    }
}

- (void) cdv_notification_rebroadcastApplication:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *) settings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LDDidRegisterUserNotificationSettings" object:settings];
    
    if (ldDidRegisterUserNotificationSettings) {
        [self cdv_notification_rebroadcastApplication:application didRegisterUserNotificationSettings:settings];
    }
}

+ (UILocalNotification*) localLaunchNotification
{
    return ldLaunchLocalNotification;
}

@end
