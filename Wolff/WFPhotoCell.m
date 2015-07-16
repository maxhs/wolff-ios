//
//  WFPhotoCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFPhotoCell.h"
#import "Constants.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface WFPhotoCell () {
    
}

@end

@implementation WFPhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.landscapeArtImageView setAlpha:0.f];
    [self.portraitArtImageView setAlpha:0.f];
    
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
    
    [_privateLabel setHidden:YES];
    [_privateLabel setText:@"Private"];
    [_privateLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
    [_privateLabel setTextColor:[UIColor lightGrayColor]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (UIImage *)getRasterizedImageCopy {
    CGSize size = self.frame.size;
    size.width += 10;
    size.height += 10;
    UIGraphicsBeginImageContextWithOptions(size, self.isOpaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)configureForPhoto:(Photo *)photo {
    if (!photo.slideImageUrl.length && photo.image){
        [self.portraitArtImageView setHidden:NO];
        [self.landscapeArtImageView setHidden:YES];
        [self.portraitArtImageView setImage:photo.image];
        [UIView animateWithDuration:.23 animations:^{
            [self.portraitArtImageView setAlpha:1.0];
        } completion:^(BOOL finished) {
            [self.portraitArtImageView.layer setShouldRasterize:YES];
            self.portraitArtImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }];
    } else if (photo.isLandscape){
        [self.portraitArtImageView setHidden:YES];
        [self.landscapeArtImageView setHidden:NO];
        [self.landscapeArtImageView sd_setImageWithURL:[NSURL URLWithString:photo.slideImageUrl] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.23 animations:^{
                [self.landscapeArtImageView setAlpha:1.0];
            } completion:^(BOOL finished) {
                [self.landscapeArtImageView.layer setShouldRasterize:YES];
                self.landscapeArtImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }];
    } else {
        [self.portraitArtImageView setHidden:NO];
        [self.landscapeArtImageView setHidden:YES];
        [self.portraitArtImageView sd_setImageWithURL:[NSURL URLWithString:photo.slideImageUrl] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.23 animations:^{
                [self.portraitArtImageView setAlpha:1.0];
            } completion:^(BOOL finished) {
                [self.portraitArtImageView.layer setShouldRasterize:YES];
                self.portraitArtImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }];
    }
    
    if ([photo.privatePhoto isEqualToNumber:@YES]){
        [_privateLabel setHidden:NO];
    } else {
        [_privateLabel setHidden:YES];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
