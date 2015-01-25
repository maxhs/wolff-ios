//
//  WFMenuViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/21/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WFMenuDelegate <NSObject>

@required
- (void)showSettings;
- (void)showProfile;
- (void)logout;
@end

@interface WFMenuViewController : UITableViewController

@property (weak, nonatomic) id<WFMenuDelegate> menuDelegate;

@end
