//
//  WFNewLightTableViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFNewLightTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *selectedArt;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)dismiss;
@end
