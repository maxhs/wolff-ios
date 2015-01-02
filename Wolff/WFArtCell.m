//
//  WFArtCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFArtCell.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFArtCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [_slideContainerView setBackgroundColor:[UIColor colorWithWhite:.95 alpha:1]];
    _slideContainerView.layer.cornerRadius = 14.f;
    _slideContainerView.layer.shouldRasterize = YES;
    
    _slideContainerView.layer.backgroundColor = [UIColor colorWithWhite:.95 alpha:1].CGColor;
    _slideContainerView.layer.shadowColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
    _slideContainerView.layer.shadowOpacity = .4f;
    _slideContainerView.layer.shadowOffset = CGSizeMake(1.3f, 1.7f);
    _slideContainerView.layer.shadowRadius = 1.3f;
    
    _slideContainerView.clipsToBounds = NO;
}

- (UIImage *)getRasterizedImageCopy {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.artImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)configureForArt:(Art *)art {
    if (art.photo.largeImageUrl.length){
        [self.artImageView sd_setImageWithURL:[NSURL URLWithString:art.photo.largeImageUrl]  placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.23 animations:^{
                [self.artImageView setAlpha:1.0];
            }];
        }];
        
    } else {
        [self.artImageView setImage:nil];
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
