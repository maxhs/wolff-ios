//
//  WFLoadingCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 7/19/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLoadingCell.h"
#import "Constants.h"

@implementation WFLoadingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.loadingLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
}

@end
