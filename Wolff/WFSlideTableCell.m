//
//  WFSlideTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideTableCell.h"

@implementation WFSlideTableCell

- (void)awakeFromNib {
    [_slideContainerView setBackgroundColor:[UIColor blackColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForSlide:(Slide *)slide {
    
}

@end
