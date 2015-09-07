//
//  WFAppDelegate.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MagicalRecord/MagicalRecord.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "Constants.h"
#import "ProgressHUD.h"
#import "User+helper.h"

@protocol WFLoginDelegate <NSObject>
@optional
- (void)userAlreadyExists;
- (void)incorrectEmail;
- (void)incorrectPassword;
@required
- (void)loginSuccessful;
- (void)logout;
@end

@interface WFAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) User *currentUser;
@property (weak, nonatomic) id<WFLoginDelegate> loginDelegate;
@property BOOL connected;

- (void)connectWithParameters:(NSMutableDictionary*)parameters forSignup:(BOOL)signup;
- (void)setUserDefaults;
- (void)logout;

@end
