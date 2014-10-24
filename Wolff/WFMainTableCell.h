//
//  WFMainTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"

@interface WFMainTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *artLabel;

- (void)configureForArt:(Art*)art;

@end
