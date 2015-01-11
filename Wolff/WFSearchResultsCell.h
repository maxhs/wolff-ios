//
//  WFSearchResultsCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "Photo+helper.h"

@interface WFSearchResultsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *artLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageTile;
- (void) configureForPhoto:(Photo*)photo;

@end
