//
//  WFNotificationCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Notification+helper.h"

@interface WFNotificationCell : UITableViewCell

- (void)configureForNotificaiton:(Notification*)notification;
@end
