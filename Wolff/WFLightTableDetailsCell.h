//
//  WFLightTableDetailsCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightTable+helper.h"

@protocol WFLightTableDetailsDelegate <NSObject>

- (void)doneEditing;
- (void)didCreateLightTable:(LightTable*)table;
- (void)didUpdateLightTable:(LightTable*)table;
- (void)showOwners;
- (void)showMembers;
//- (void)didDeleteLightTable:(LightTable*)table;
@end

@interface WFLightTableDetailsCell : UICollectionViewCell <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (weak, nonatomic) UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) id<WFLightTableDetailsDelegate>lightTableDelegate;
@property (strong, nonatomic) NSMutableOrderedSet *photos;
- (void)configureForLightTable:(LightTable*)lightTable;

@end
