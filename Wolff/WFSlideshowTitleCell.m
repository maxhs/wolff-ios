//
//  WFSlideshowTitleCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/23/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideshowTitleCell.h"
#import "Constants.h"
#import "User+helper.h"
#import "Institution+helper.h"

@implementation WFSlideshowTitleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleHeadline forFont:kMuseoSansThin] size:0]];
    [_authorLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_institutionLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_wolffLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSans] size:0]];
}

- (void)configureForSlideshow:(Slideshow *)slideshow {
    [_titleLabel setText:slideshow.title];
    [_authorLabel setText:slideshow.owner.fullName];
    [_institutionLabel setText:slideshow.owner.institution.name];
    [_wolffLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77f]];
    [_wolffIcon setAlpha:.77f];
}

@end
