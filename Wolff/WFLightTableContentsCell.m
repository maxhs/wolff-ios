//
//  WFLightTableContentsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/30/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableContentsCell.h"
#import "Art+helper.h"
#import "Constants.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation WFLightTableContentsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _slideContainerView.backgroundColor = kSlideBackgroundColor;
    _slideContainerView.layer.cornerRadius = 14.f;
    _slideContainerView.layer.backgroundColor = kSlideBackgroundColor.CGColor;
    _slideContainerView.layer.shadowColor = kSlideShadowColor.CGColor;
    _slideContainerView.layer.shadowOpacity = .4f;
    _slideContainerView.layer.shadowOffset = CGSizeMake(1.3f, 1.7f);
    _slideContainerView.layer.shadowRadius = 1.3f;
    _slideContainerView.clipsToBounds = NO;
    _slideContainerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _slideContainerView.layer.shouldRasterize = YES;
}

- (void)configureForPhoto:(Photo *)photo {
    [_titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_titleLabel setTextColor:[UIColor whiteColor]];
    [_titleLabel setText:photo.art.title];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    
    if (photo.isLandscape){
        [self.portraitArtImageView setHidden:YES];
        [self.landscapeArtImageView setHidden:NO];
        [self.landscapeArtImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [self.landscapeArtImageView setImage:image];
            if (response){
                [UIView animateWithDuration:.23 animations:^{
                    [self.landscapeArtImageView setAlpha:1.0];
                } completion:^(BOOL finished) {
                    [self.landscapeArtImageView.layer setShouldRasterize:YES];
                    self.landscapeArtImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
                }];
            } else {
                [self.landscapeArtImageView setAlpha:1.0];
            }
        } failure:^(NSURLRequest * request, NSHTTPURLResponse * response, NSError * error) {
            
        }];
    } else {
        [self.landscapeArtImageView setHidden:YES];
        [self.portraitArtImageView setHidden:NO];
        [self.self.portraitArtImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [self.portraitArtImageView setImage:image];
            if (response){
                [UIView animateWithDuration:.23 animations:^{
                    [self.portraitArtImageView setAlpha:1.0];
                } completion:^(BOOL finished) {
                    [self.portraitArtImageView.layer setShouldRasterize:YES];
                    self.portraitArtImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
                }];
            } else {
                [self.portraitArtImageView setAlpha:1.0];
            }
        } failure:^(NSURLRequest * request, NSHTTPURLResponse * response, NSError * error) {
            
        }];
    }
}

@end
