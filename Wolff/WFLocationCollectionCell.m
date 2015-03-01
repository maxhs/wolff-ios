//
//  WFLocationCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLocationCollectionCell.h"
#import "Constants.h"
#import "Photo+helper.h"
#import "Art+helper.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFLocationCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_locationNameLabel setTextAlignment:NSTextAlignmentLeft];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_locationCoverImage setAlpha:0.0];
}

- (void)configureForLocation:(Location *)location {
    NSMutableAttributedString *locationString;
    if (location.name.length){
        locationString = [[NSMutableAttributedString alloc] initWithString:location.name attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]}];
    } else {
        locationString = [[NSMutableAttributedString alloc] initWithString:location.name attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]}];
    }
    
    NSAttributedString *geographyString;
    if (location.city.length){
        geographyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",location.city] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]}];
    } else if (location.country.length){
        geographyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",location.country] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]}];
    }
    
    if (geographyString.length && locationString.length){
        [locationString appendAttributedString:geographyString];
        [_locationNameLabel setAttributedText:locationString];
    } else if (locationString.length){
        [_locationNameLabel setAttributedText:locationString];
    } else if (geographyString.length){
        [_locationNameLabel setAttributedText:geographyString];
    } else {
        NSAttributedString *noLocationString = [[NSAttributedString alloc] initWithString:@"No location name listed" attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]}];
        [_locationNameLabel setAttributedText:noLocationString];
    }
    
    __block Photo *coverPhoto;
    [location.arts enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
        if (art.photo){
            coverPhoto = art.photo;
            *stop = YES;
        }
    }];
    if (coverPhoto.slideImageUrl.length){
        [_locationCoverImage setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
        [_locationCoverImage sd_setImageWithURL:[NSURL URLWithString:coverPhoto.slideImageUrl] placeholderImage:nil options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:kFastAnimationDuration animations:^{
                [_locationCoverImage setAlpha:1.0];
            }];
        }];
    } else {
        [_locationCoverImage setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
        [_locationCoverImage setImage:nil];
        [_locationCoverImage setAlpha:1.0];
    }
}

@end
