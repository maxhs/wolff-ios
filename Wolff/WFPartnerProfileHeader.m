//
//  WFPartnerProfileHeader.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFPartnerProfileHeader.h"
#import "Constants.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation WFPartnerProfileHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
    [_locationLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_partnerSinceLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    
    [_photoCountButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_photoCountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_photoCountButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    _photoCountButton.layer.cornerRadius = 7.f;
    _photoCountButton.clipsToBounds = YES;
    
    [_slideshowsButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_slideshowsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_slideshowsButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    _slideshowsButton.layer.cornerRadius = 7.f;
    _slideshowsButton.clipsToBounds = YES;
    [_slideshowsButton setHidden:YES];
    
    [_lightTablesButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_lightTablesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_lightTablesButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    _lightTablesButton.layer.cornerRadius = 7.f;
    _lightTablesButton.clipsToBounds = YES;
    [_lightTablesButton setHidden:YES];
    
    [_urlButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
    [_urlButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
}

- (void)configureForPartner:(Partner *)partner {
    [_partnerPhotoButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    [_partnerPhotoButton sd_setImageWithURL:[NSURL URLWithString:partner.avatarMedium] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"transparentIconWhite"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [UIView animateWithDuration:.23 animations:^{
            [_partnerPhotoButton setAlpha:1.0];
        }];
    }];
    
    [_nameLabel setText:[NSString stringWithFormat:@"%@",partner.name]];
    [_locationLabel setText:partner.locationsToSentence];
    
    if (partner.url.length){
        [_urlButton setHidden:NO];
        [_urlButton setTitle:partner.url forState:UIControlStateNormal];
    } else {
        [_urlButton setHidden:NO];
    }
}

@end
