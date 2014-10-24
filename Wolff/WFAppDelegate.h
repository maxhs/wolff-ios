//
//  WFAppDelegate.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@protocol WFLoginDelegate <NSObject>

@optional
- (void)incorrectEmail;
- (void)incorrectPassword;
@required
- (void)loginSuccessful;
@end

@interface WFAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@property (strong, nonatomic) User *currentUser;
@property (weak, nonatomic) id<WFLoginDelegate> loginDelegate;

- (void)connectWithEmail:(NSString*)email andPassword:(NSString*)password;
- (void)setUserDefaults;

@end
