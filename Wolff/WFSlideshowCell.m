//
//  WFSlideshowCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowCell.h"
#import "Constants.h"

@implementation WFSlideshowCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    [selectionView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    self.selectedBackgroundView = selectionView;
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self setBackgroundColor:[UIColor clearColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
