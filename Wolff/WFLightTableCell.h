//
//  WFLightTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "LightTable+helper.h"

@interface WFLightTableCell : UITableViewCell <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *tableLabel;
@property (weak, nonatomic) IBOutlet UILabel *pieceCountLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *leaveButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
- (void)configureForTable:(LightTable*)lightTable;

@end
