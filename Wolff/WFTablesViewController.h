//
//  WFTablesViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

// This protocol is only to silence the compiler since we're using one of two different classes.
@protocol WFTablesViewControllerPanTarget <NSObject>

-(void)userDidPan:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer;

@end

@interface WFTablesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<WFTablesViewControllerPanTarget> panTarget;

-(id)initWithPanTarget:(id<WFTablesViewControllerPanTarget>)panTarget;
- (void)dismiss;
@end
