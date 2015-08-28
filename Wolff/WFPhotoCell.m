//
//  WFPhotoCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFPhotoCell.h"
#import "Constants.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

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
    
    [_partnerBadge setHidden:YES];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.portraitArtImageView setImage:nil];
    [self.portraitArtImageView setAlpha:0.0];
    [self.landscapeArtImageView setImage:nil];
    [self.landscapeArtImageView setAlpha:0.0];
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
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [self.landscapeArtImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [self.landscapeArtImageView setImage:image];
            if (response){
                [UIView animateWithDuration:kFastAnimationDuration animations:^{
                    [self.landscapeArtImageView setAlpha:1.0];
                }];
            } else {
                [self.landscapeArtImageView setAlpha:1.0];
            }
        } failure:NULL];
    
    } else {
        [self.portraitArtImageView setHidden:NO];
        [self.landscapeArtImageView setHidden:YES];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [self.portraitArtImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [self.portraitArtImageView setImage:image];
            if (response){
                [UIView animateWithDuration:kFastAnimationDuration animations:^{
                    [self.portraitArtImageView setAlpha:1.0];
                }];
            } else {
                [self.portraitArtImageView setAlpha:1.0];
            }
        } failure:NULL];
    }
    
    [_privateLabel setHidden:[photo.privatePhoto isEqualToNumber:@YES] ? NO : YES];
    [_partnerBadge setHidden:photo.partners.count ? NO : YES];
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
