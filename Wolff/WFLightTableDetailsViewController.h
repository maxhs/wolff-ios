//
//  WFLightTableDetailsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Table+helper.h"

@interface WFLightTableDetailsViewController : UIViewController

@property (strong, nonatomic) NSMutableOrderedSet *photos;
@property (strong, nonatomic) NSNumber *tableId;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property BOOL showKey;
- (void)dismiss;

@end
