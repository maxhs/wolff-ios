//
//  WFGroupCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightTable+helper.h"

@interface WFTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *tableLabel;
- (void)configureForTable:(LightTable*)table;
@end
