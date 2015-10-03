//
//  WFAppDelegate.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import <Mixpanel/Mixpanel.h>
#import <Crashlytics/Crashlytics.h>
#import "WFAlert.h"
#import "WFSlideshowViewController.h"
#import "WFLoginViewController.h"
#import "WFNoRotateNavController.h"
#import "WFWalkthroughViewController.h"
#import "WFNewArtViewController.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "WFTracking.h"

@implementation WFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Crashlytics startWithAPIKey:@"fdf66a0a10b6fc2a0f7052c9758873dc992773d5"];
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelError];
    //[Stripe setDefaultPublishableKey:kStripePublishableKey];
    [self customizeAppearance];
    
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Launch"];
    
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kApiBaseUrl]];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:API_LOGIN password:API_KEY];
    [_manager.requestSerializer setValue:(IDIOM == IPAD) ? @"2" : @"1" forHTTPHeaderField:@"device_type"];
    [self setupConnectionObserver];

    // LAUNCH_DATE gets set after the welcome walkthrough
    if (![[NSUserDefaults standardUserDefaults] objectForKey:LAUNCH_DATE]){
        [self newInstall];
    }
    NSLog(@"Base url: %@",kApiBaseUrl);
    NSLog(@"Bundle name: %@",[[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey]);
    if (IDIOM == IPAD && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPadToken]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPadToken] forKey:@"mobile_token"];
        [self connectWithParameters:parameters forSignup:NO];   // automatically log the user in
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPhoneToken]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPhoneToken] forKey:@"mobile_token"];
        [self connectWithParameters:parameters forSignup:NO];   // automatically log the user in
    }
    return YES;
}

- (void)setupConnectionObserver {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                //NSLog(@"Connected");
                _connected = YES;
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                //NSLog(@"Not online");
                _connected = NO;
                [self offlineNotification];
                break;
        }
    }];
}

- (void)newInstall {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LAUNCH_DATE];
}

- (void)connectWithParameters:(NSMutableDictionary *)parameters forSignup:(BOOL)signup {
    if (IDIOM == IPAD && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPadToken]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPadToken] forKey:@"mobile_token"];
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPhoneToken]) {
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsiPhoneToken] forKey:@"mobile_token"];
    }
    if (signup){
        [parameters setObject:@YES forKey:@"signup"];
        [ProgressHUD show:@"Signing up..."];
    } else {
        [ProgressHUD show:@"Logging in..."];
    }
    [_manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success connecting: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            NSDictionary *userDict = [responseObject objectForKey:@"user"];
            self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!self.currentUser){
                self.currentUser = [User MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [self.currentUser populateFromDictionary:userDict];
            [self setUserDefaults];
            
            if (self.currentUser.authenticationToken){
                [self.manager.requestSerializer setValue:self.currentUser.authenticationToken forKey:@"authentication_token"];
            }
            if (signup){
                [WFTracking aliasForCurrentUser:self.currentUser.identifier];
            }
            [WFTracking setPeopleProperty:self.currentUser.firstName to:@"$first_name"];
            [WFTracking setPeopleProperty:self.currentUser.lastName to:@"$last_name"];
            [WFTracking setPeopleProperty:self.currentUser.email to:@"$email"];
            
            NSMutableDictionary *trackingProperties = [WFTracking generateTrackingPropertiesForUser:self.currentUser];
            [WFTracking trackEvent:signup ? @"Signup" : @"Login" withProperties:trackingProperties];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginSuccessful)]) {
                    [self.loginDelegate loginSuccessful];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:LOGGED_IN object:nil];
            }];
            
            //only ask for push notifications when a user has successfully logged in
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Response string: %@",operation.responseString);
        if (!_connected) {
            [self offlineNotification];
        } else if ([operation.responseString isEqualToString:kNoEmail]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectEmail)]) {
                [self.loginDelegate incorrectEmail];
            }
        } else if ([operation.responseString isEqualToString:kUserAlreadyExists]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(userAlreadyExists)]) {
                [self.loginDelegate userAlreadyExists];
            }
        } else if ([operation.responseString isEqualToString:kIncorrectPassword]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectPassword)]) {
                [self.loginDelegate incorrectPassword];
            }
        } else if ([operation.responseString isEqualToString:kInvalidToken]){
            [self logout];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        [ProgressHUD dismiss];
    }];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if (IDIOM == IPAD){
        return UIInterfaceOrientationMaskLandscape;
    } else {
        UIViewController *presentedViewController = window.rootViewController.presentedViewController;
        if (presentedViewController) {
            if ([presentedViewController isKindOfClass:[WFLoginViewController class]] || [presentedViewController isKindOfClass:[WFNewArtViewController class]] || [presentedViewController isKindOfClass:[WFWalkthroughViewController class]]) {
                return UIInterfaceOrientationMaskPortrait;
            } else if ([presentedViewController isKindOfClass:[WFSlideshowViewController class]]){
                return UIInterfaceOrientationMaskLandscape;
            } else if ([presentedViewController isKindOfClass:[WFNoRotateNavController class]]){
                if ([[[(WFNoRotateNavController*)presentedViewController viewControllers] firstObject] isKindOfClass:[WFSlideshowViewController class]]){
                    return UIInterfaceOrientationMaskLandscape;
                } else if ([[[(WFNoRotateNavController*)presentedViewController viewControllers] firstObject] isKindOfClass:[WFNewArtViewController class]]){
                    return UIInterfaceOrientationMaskPortrait;
                }
            }
        }
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
    }
}

- (void)setUserDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:self.currentUser.identifier forKey:kUserDefaultsId];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentUser.email forKey:kUserDefaultsEmail];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentUser.firstName forKey:kUserDefaultsFirstName];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentUser.lastName forKey:kUserDefaultsLastName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[Crashlytics sharedInstance] setUserIdentifier:self.currentUser.identifier.stringValue];
    [[Crashlytics sharedInstance] setUserEmail:self.currentUser.email];
    [[Crashlytics sharedInstance] setUserName:self.currentUser.fullName];
}

- (void)customizeAppearance {
    /*for (NSString* family in [UIFont familyNames]){
        NSLog(@"%@", family);
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
            NSLog(@"  %@", name);
    }*/
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kMuseoSansLight size:20]}];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kMuseoSans size:15]} forState:UIControlStateNormal];
    
    [[UISwitch appearance] setTintColor:kSaffronColor];
    [[UISwitch appearance] setOnTintColor:kSaffronColor];
    [[UIProgressView appearance] setTintColor:[UIColor colorWithWhite:.5 alpha:.3]];
    [[UIProgressView appearance] setTrackTintColor:[UIColor colorWithWhite:.5 alpha:.15]];
    
    [self.window setBackgroundColor:[UIColor blackColor]];
    [self.window setTintColor:[UIColor blackColor]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)pushMessage {
    [[Mixpanel sharedInstance] trackPushNotification:pushMessage];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    //NSLog(@"didRegisterUserNotificationSettings: %@",notificationSettings);
    //NSLog(@"Current user notification cettings: %@",[[UIApplication sharedApplication] currentUserNotificationSettings]);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kUserDefaultsDeviceToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [[NSUserDefaults standardUserDefaults]  objectForKey:kUserDefaultsDeviceToken]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults]  objectForKey:kUserDefaultsDeviceToken] forKey:@"token"];
        [_manager POST:[NSString stringWithFormat:@"users/%@/push_tokens",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success posting a push token: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failure posting a push token: %@",error.description);
        }];
    }
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)offlineNotification {
    [WFAlert show:@"Your device appears to have gone offline." withTime:2.7f];
}

- (void)logout {
    [WFTracking trackEvent:@"Logout" withProperties:nil];
    
    // preserve our counters
    NSNumber *artMetadataViewCount = [[NSUserDefaults standardUserDefaults] objectForKey:ART_METADATA_VIEW_COUNT];
    NSNumber *catalogViewCount = [[NSUserDefaults standardUserDefaults] objectForKey:CATALOG_VIEW_COUNT];
    NSDate *launchDate = [[NSUserDefaults standardUserDefaults] objectForKey:LAUNCH_DATE];
    self.currentUser = nil;

    //[self cleanAndResetDB];
    [[NSManagedObjectContext MR_defaultContext] MR_deleteObjects:[Photo MR_findAll]];
    [[NSManagedObjectContext MR_defaultContext] MR_deleteObjects:[Art MR_findAll]];
    [[NSManagedObjectContext MR_defaultContext] MR_deleteObjects:[Slideshow MR_findAll]];
    [[NSManagedObjectContext MR_defaultContext] MR_deleteObjects:[Slide MR_findAll]];
    [[NSManagedObjectContext MR_defaultContext] MR_deleteObjects:[LightTable MR_findAll]];
    [[NSManagedObjectContext MR_defaultContext] MR_deleteObjects:[Favorite MR_findAll]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
    [[NSUserDefaults standardUserDefaults] setObject:catalogViewCount forKey:CATALOG_VIEW_COUNT];
    [[NSUserDefaults standardUserDefaults] setObject:artMetadataViewCount forKey:ART_METADATA_VIEW_COUNT];
    [[NSUserDefaults standardUserDefaults] setObject:launchDate forKey:LAUNCH_DATE];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(logout)]){
        [self.loginDelegate logout];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGGED_OUT object:nil];
    [ProgressHUD dismiss];
}

- (void)cleanAndResetDB {
    NSError *error = nil;
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]];
    [MagicalRecord cleanUp];
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
        [MagicalRecord setupAutoMigratingCoreDataStack];
    } else{
        NSLog(@"Error deleting persistent store description: %@ %@", error.description,storeURL);
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [MagicalRecord cleanUp];
}

@end
