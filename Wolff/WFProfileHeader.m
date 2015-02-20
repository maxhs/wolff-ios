//
//  WFProfileHeader.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFProfileHeader.h"
#import "Constants.h"
#import <SDWebImage/UIButton+WebCache.h>

@implementation WFProfileHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
    [_institutionLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_locationLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_userSinceLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    
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
    
    [_lightTablesButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_lightTablesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_lightTablesButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    _lightTablesButton.layer.cornerRadius = 7.f;
    _lightTablesButton.clipsToBounds = YES;
    
    [_urlButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
    [_urlButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
}
- (void)configureForUser:(User *)user {
    [_userPhotoButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    [_userPhotoButton sd_setImageWithURL:[NSURL URLWithString:user.avatarLarge] forState:UIControlStateNormal placeholderImage:[UIImage imageNamed:@"transparentIconWhite"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [UIView animateWithDuration:.23 animations:^{
            [_userPhotoButton setAlpha:1.0];
        }];
    }];
    NSString *prefix = user.prefix && user.prefix.length ? [NSString stringWithFormat:@"%@ ",user.prefix] : @"";
    [_nameLabel setText:[NSString stringWithFormat:@"%@%@",prefix,user.fullName]];
    [_institutionLabel setText:user.institution.name];
    
    [_locationLabel setText:user.location];
    
    if (user.url.length){
        [_urlButton setHidden:NO];
        [_urlButton setTitle:user.url forState:UIControlStateNormal];
    } else {
        [_urlButton setHidden:NO];
    }
}
@end
