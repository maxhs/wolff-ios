//
//  WFRightMenuTableViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/19/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WFRightMenuDelegate <NSObject>

- (void)showNewArt;
- (void)showSettings;
- (void)showNotifications;
- (void)logout;

@end

@interface WFRightMenuTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<WFRightMenuDelegate> rightMenuDelegate;
@end
