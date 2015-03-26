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
#import <SDWebImage/SDImageCache.h>
#import "WFAlert.h"
#import <Stripe/Stripe.h>

@implementation WFAppDelegate
@synthesize manager = _manager;
@synthesize connected = _connected;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Crashlytics startWithAPIKey:@"fdf66a0a10b6fc2a0f7052c9758873dc992773d5"];
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [Stripe setDefaultPublishableKey:kStripePublishableKeyTest];
    [self hackForPreloadingKeyboard];
    [self customizeAppearance];
    
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Launch"];
    
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kApiBaseUrl]];
    [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"wolff_mobile" password:@"0fd11d82b574e0b13fc66b6227c4925c"];
    [_manager.requestSerializer setValue:(IDIOM == IPAD) ? @"2" : @"1" forHTTPHeaderField:@"device_type"];
    
    [self setupConnectionObserver];

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsMobileToken]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsMobileToken] forKey:@"mobile_token"];
        [self connectWithParameters:parameters];   // automatically log the user in if they
    }
    //[self initLayer];
    return YES;
}

//- (void)initLayer {
//    NSUUID *appID = [[NSUUID alloc] initWithUUIDString:@"7d49bc9e-cd98-11e4-b5f2-eae8c100164f"];
//    self.layerClient = [LYRClient clientWithAppID:appID];
//    [self.layerClient connectWithCompletion:^(BOOL success, NSError *error) {
//        if (!success) {
//            NSLog(@"Failed to connect to Layer: %@", error);
//        } else {
//            // For the purposes of this Quick Start project, let's authenticate as a user named 'Device'.  Alternatively, you can authenticate as a user named 'Simulator' if you're running on a Simulator.
//            NSString *userIDString = @"Device";
//            // Once connected, authenticate user.
//            // Check Authenticate step for authenticateLayerWithUserID source
//            [self authenticateLayerWithUserID:userIDString completion:^(BOOL success, NSError *error) {
//                if (!success) {
//                    NSLog(@"Failed Authenticating Layer Client with error:%@", error);
//                }
//            }];
//        }
//    }];
//}

- (void)setupConnectionObserver {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"Connected");
                _connected = YES;
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                NSLog(@"Not online");
                _connected = NO;
                [self offlineNotification];
                break;
        }
    }];
}

- (void)hackForPreloadingKeyboard {
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
}

- (void)connectWithParameters:(NSMutableDictionary *)parameters {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
    }
    [_manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success connecting: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            NSDictionary *userDict = [responseObject objectForKey:@"user"];
            _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!_currentUser){
                _currentUser = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [_currentUser populateFromDictionary:userDict];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self setUserDefaults];
                if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginSuccessful)]) {
                    [self.loginDelegate loginSuccessful];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessful" object:nil];
            }];
        }
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (!_connected) {
            [self offlineNotification];
        } else if ([operation.responseString isEqualToString:kNoEmail]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectEmail)]) {
                [self.loginDelegate incorrectEmail];
            }
        } else if ([operation.responseString isEqualToString:kIncorrectPassword]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectPassword)]) {
                [self.loginDelegate incorrectPassword];
            }
        } else if ([operation.responseString isEqualToString:kInvalidToken]){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LoggedOut" object:nil];
            [self logout];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        //NSLog(@"Failed to connect: %@",error.description);
        NSLog(@"Response string: %@",operation.responseString);
    }];
}

- (void)setUserDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.identifier forKey:kUserDefaultsId];
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.email forKey:kUserDefaultsEmail];
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.mobileToken forKey:kUserDefaultsMobileToken];
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.firstName forKey:kUserDefaultsFirstName];
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.lastName forKey:kUserDefaultsLastName];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kMuseoSansSemibold size:15]} forState:UIControlStateNormal];
    
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
            NSLog(@"Success posting a push token: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure posting a push token: %@",error.description);
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
    //[self cleanAndResetDB];
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
