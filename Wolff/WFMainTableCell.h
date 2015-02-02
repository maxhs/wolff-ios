//
//  WFMainTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "Table+helper.h"

@protocol WFLightTableCellDelegate <NSObject>
- (void)deleteLightTable:(NSNumber*)lightTableId;
- (void)leaveLightTable:(NSNumber*)lightTableId;
- (void)editLightTable:(NSNumber*)lightTableId;
@end

@interface WFMainTableCell : UITableViewCell <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *tableLabel;
@property (weak, nonatomic) IBOutlet UILabel *pieceCountLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) id<WFLightTableCellDelegate> delegate;
- (void)configureForTable:(Table*)lightTable;

@end
