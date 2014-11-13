//
//  WFAppDelegate.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#define MIXPANEL_TOKEN @"b091c81f24a93b828683bb5c3c260278"

#import "WFAppDelegate.h"
#import <Mixpanel/Mixpanel.h>

@implementation WFAppDelegate
@synthesize manager = _manager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"iPad: Launch"];
    
    _manager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[NSURL URLWithString:kApiBaseUrl]];
    [_manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"wolff_mobile" password:@"e065c6aaebbdaec80f53e1a9c7c1eeb8"];
    [_manager.requestSerializer setValue:(IDIOM == IPAD) ? @"2" : @"1" forHTTPHeaderField:@"device_type"];
    
    [self customizeAppearance];

    // automatically log the user in if they
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsEmail] && [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]){
        NSLog(@"app did finish launching and we should be automatically logging in");
        [self connectWithEmail:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsEmail] andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsPassword]];
    }
    
    return YES;
}

- (void)connectWithEmail:(NSString*)email andPassword:(NSString*)password {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsDeviceToken] forKey:@"device_token"];
    }
    
    [parameters setObject:email forKey:@"email"];
    [parameters setObject:password forKey:@"password"];
    
    [ProgressHUD show:@"Logging in..."];
    
    [_manager POST:[NSString stringWithFormat:@"%@/sessions",kApiBaseUrl] parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success connecting: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            NSDictionary *userDict = [responseObject objectForKey:@"user"];
            _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!_currentUser){
                _currentUser = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [_currentUser populateFromDictionary:userDict];
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:kUserDefaultsEmail];
            [[NSUserDefaults standardUserDefaults] setObject:password forKey:kUserDefaultsPassword];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self setUserDefaults];
            
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginSuccessful)]) {
                [self.loginDelegate loginSuccessful];
            }
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"Success logging in the user: %u",success);
            }];
        }
        [ProgressHUD dismiss];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([operation.responseString isEqualToString:kNoEmail]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectEmail)]) {
                [self.loginDelegate incorrectEmail];
            }
        } else if ([operation.responseString isEqualToString:kIncorrectPassword]){
            if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(incorrectPassword)]) {
                [self.loginDelegate incorrectPassword];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to log you in." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        }
        //NSLog(@"Failed to connect: %@",error.description);
        //NSLog(@"Response string: %@",operation.responseString);
    }];
}

- (void)setUserDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.identifier forKey:kUserDefaultsId];
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.email forKey:kUserDefaultsEmail];
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
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kLato size:21]}];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:kLato size:18]} forState:UIControlStateNormal];
    
    [self.window setBackgroundColor:[UIColor blackColor]];
    [self.window setTintColor:[UIColor blackColor]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [MagicalRecord cleanUp];
}

@end
