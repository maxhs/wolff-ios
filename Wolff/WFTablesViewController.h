//
//  WFTablesViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Table+helper.h"

@protocol WFLightTablesDelegate <NSObject>

@optional
-(void)userDidPan:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer;
-(void)lightTableSelected:(NSNumber*)lightTableId;

@end

@interface WFTablesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *lightTables;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<WFLightTablesDelegate> lightTableDelegate;

-(id)initWithPanTarget:(id<WFLightTablesDelegate>)lightTableDelegate;
- (void)dismiss;
@end
