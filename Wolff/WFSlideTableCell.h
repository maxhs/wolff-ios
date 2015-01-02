//
//  WFSlideTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"

@interface WFSlideTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *slideNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *artImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *artImageView2;

- (void)configureForSlide:(Slide*)slide withSlideNumber:(NSInteger)number;

@end
