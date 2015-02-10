//
//  WFLocationCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLocationCollectionCell.h"
#import "Constants.h"

@implementation WFLocationCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_locationNameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_locationNameLabel setTextAlignment:NSTextAlignmentLeft];
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (void)configureForLocation:(Location *)location {
    if (location.name.length){
        [_locationNameLabel setText:location.name];
    } else if (location.city.length){
        [_locationNameLabel setText:location.city];
    } else if (location.country.length){
        [_locationNameLabel setText:location.country];
    }
}

@end
