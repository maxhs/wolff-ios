//
//  WFLightTablesViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightTable+helper.h"
#import "Slideshow+helper.h"
#import "Photo+helper.h"

@protocol WFLightTablesDelegate <NSObject>

@optional
- (void)userDidPan:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer;
- (void)newLightTable;
- (void)lightTableSelected:(LightTable*)lightTable;
- (void)lightTableDeselected:(LightTable*)lightTable;
- (void)undropPhotoFromLightTable:(LightTable*)lightTable;
- (void)batchFavorite;
@end

@interface WFLightTablesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property BOOL slideshowShareMode;
@property (strong, nonatomic) Photo *photo;
@property (strong, nonatomic) Slideshow *slideshow;
@property (strong, nonatomic) NSMutableArray *lightTables;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<WFLightTablesDelegate> lightTableDelegate;

-(id)initWithPanTarget:(id<WFLightTablesDelegate>)lightTableDelegate;
- (void)dismiss;
@end
