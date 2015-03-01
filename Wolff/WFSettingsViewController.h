//
//  WFSettingsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@protocol WFSettingsDelegate <NSObject>

- (void)logout;

@end

@interface WFSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *footerContainerView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) User *currentUser;
@property (weak, nonatomic) id<WFSettingsDelegate> settingsDelegate;

- (void)dismiss;

@end
