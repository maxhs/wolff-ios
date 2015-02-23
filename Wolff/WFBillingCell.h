//
//  WFBillingCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/17/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card+helper.h"

@interface WFBillingCell : UITableViewCell
- (void)configureForCard:(Card*)card;
@end
