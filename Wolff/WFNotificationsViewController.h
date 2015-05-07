//
//  WFNotificationsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Notification+helper.h"

@protocol WFNotificationsDelegate <NSObject>

- (void)didSelectNotificationWithId:(NSNumber*)notificationId;
- (void)setNotificationColor;

@end

@interface WFNotificationsViewController : UITableViewController

@property (weak, nonatomic) id<WFNotificationsDelegate>notificationsDelegate;

@end
