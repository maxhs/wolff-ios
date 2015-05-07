//
//  WFLightTableDetailsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightTable+helper.h"
@protocol WFLightTableDelegate <NSObject>

@optional
- (void)didCreateLightTable:(LightTable*)table;
- (void)didJoinLightTable:(LightTable*)table;
- (void)didUpdateLightTable:(LightTable*)table;
- (void)didDeleteLightTable:(LightTable*)table;
@end
@interface WFLightTableDetailsViewController : UIViewController

@property (strong, nonatomic) NSMutableOrderedSet *photos;
@property (strong, nonatomic) LightTable *lightTable;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *scrollBackButton;
@property (weak, nonatomic) id<WFLightTableDelegate>lightTableDelegate;
@property BOOL showKey;
@property BOOL joinMode;
- (void)dismiss;

@end
