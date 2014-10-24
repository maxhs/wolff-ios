//
//  WFSlideCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideCollectionCell.h"

@implementation WFSlideCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    _slideBackgroundView.layer.cornerRadius = 13.f;
    _slideBackgroundView.clipsToBounds = YES;
    [_slideBackgroundView setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
