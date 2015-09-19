//
//  WFPartnerProfileHeader.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFPartnerProfileHeader.h"
#import "Constants.h"
#import <AFNetworking/UIButton+AFNetworking.h>

@implementation WFPartnerProfileHeader

- (void)awakeFromNib {
    [super awakeFromNib];
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:IDIOM == IPAD ? UIFontTextStyleHeadline : UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
    [_partnerSinceLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    
    [_photoCountButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_photoCountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_photoCountButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    _photoCountButton.layer.cornerRadius = 7.f;
    _photoCountButton.clipsToBounds = YES;

    [_lightTablesButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_lightTablesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_lightTablesButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    _lightTablesButton.layer.cornerRadius = 7.f;
    _lightTablesButton.clipsToBounds = YES;
    [_lightTablesButton setHidden:YES];
    
    [_urlButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansItalic] size:0]];
    [_urlButton setTitleColor:kElectricBlue forState:UIControlStateNormal];
}

- (void)configureForPartner:(Partner *)partner {
    [_nameLabel setText:[NSString stringWithFormat:@"%@",partner.name]];
    
    if (partner.publicPhotoCount.intValue > 0){
        NSString *photoCount = partner.publicPhotoCount.intValue == 1 ? @"1 image" : [NSString stringWithFormat:@"%@ images",partner.publicPhotoCount];
        [_photoCountButton setTitle:photoCount forState:UIControlStateNormal];
    } else {
        [_photoCountButton setTitle:nil forState:UIControlStateNormal];
    }
    [_partnerPhotoButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:partner.avatarMedium] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    [_partnerPhotoButton setImageForState:UIControlStateNormal withURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
        [_partnerPhotoButton setImage:image forState:UIControlStateNormal];
        [UIView animateWithDuration:.23 animations:^{
            [_partnerPhotoButton setAlpha:1.0];
        }];
    } failure:^(NSError * error) {
        
    }];
    
    if (partner.url.length){
        [_urlButton setHidden:NO];
        [_urlButton setTitle:partner.url forState:UIControlStateNormal];
    } else {
        [_urlButton setHidden:NO];
    }
}

@end
