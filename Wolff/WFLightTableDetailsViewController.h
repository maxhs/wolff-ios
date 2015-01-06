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

@property (strong, nonatomic) NSMutableArray *arts;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) Table *table;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
