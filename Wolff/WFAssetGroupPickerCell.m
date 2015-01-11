//
//  WFAssetGroupPickerCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/10/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFAssetGroupPickerCell.h"
#import "Constants.h"

@implementation WFAssetGroupPickerCell

- (void)awakeFromNib {
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self setBackgroundColor:[UIColor clearColor]];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    self.selectedBackgroundView = selectedView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
