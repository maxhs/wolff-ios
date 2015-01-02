//
//  WFSlideTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideTableCell.h"
#import "Constants.h"

@implementation WFSlideTableCell

- (void)awakeFromNib {
    [self setBackgroundColor:[UIColor blackColor]];
    [_slideContainerView setBackgroundColor:[UIColor colorWithWhite:.23 alpha:1]];
    [_slideNumberLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:.23 alpha:1]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForSlide:(Slide *)slide withSlideNumber:(NSInteger)number {
    [_slideNumberLabel setText:[NSString stringWithFormat:@"%ld",(long)number]];
}

@end
