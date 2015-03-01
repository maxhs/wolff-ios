//
//  WFLightTableDetailsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Table+helper.h"
@protocol WFLightTableDelegate <NSObject>

- (void)didCreateLightTable:(Table*)table;
- (void)didJoinLightTable:(Table*)table;
@optional
- (void)didSaveLightTable:(Table*)table;
- (void)didDeleteLightTable:(Table*)table;
@end
@interface WFLightTableDetailsViewController : UIViewController

@property (strong, nonatomic) NSMutableOrderedSet *photos;
@property (strong, nonatomic) NSNumber *tableId;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *scrollBackButton;
@property (weak, nonatomic) id<WFLightTableDelegate>lightTableDelegate;
@property BOOL showKey;
- (void)dismiss;

@end
