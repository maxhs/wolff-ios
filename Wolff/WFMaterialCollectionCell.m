//
//  WFMaterialCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFMaterialCollectionCell.h"
#import "Constants.h"
#import "Photo+helper.h"

@implementation WFMaterialCollectionCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_materialImageView setContentMode:UIViewContentModeScaleAspectFit];
    [_materialLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_materialLabel setTextColor:[UIColor whiteColor]];
}

- (void)configureForMaterial:(Material *)material {
    [_materialLabel setText:material.name];
    
}

@end
