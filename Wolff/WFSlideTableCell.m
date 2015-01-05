//
//  WFSlideTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideTableCell.h"
#import "Art+helper.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>

@implementation WFSlideTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:.17]];
    [_slideContainerView setBackgroundColor:[UIColor blackColor]];
    [_slideNumberLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:.5 alpha:1]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_artImageView1 setImage:nil];
    [_artImageView2 setImage:nil];
    [_artImageView3 setImage:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForSlide:(Slide *)slide withSlideNumber:(NSInteger)number {
    [_slideNumberLabel setText:[NSString stringWithFormat:@"%ld",(long)number]];
    if (slide){
        [_addPrompt setHidden:YES];
        if (slide.arts.count == 1){
            [_artImageView1 setHidden:NO];
            [_artImageView2 setHidden:YES];
            [_artImageView3 setHidden:YES];
            Art *art = (Art*)[slide.arts firstObject];
            [_artImageView1 sd_setImageWithURL:[NSURL URLWithString:art.photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView1 setArt:art];
                [self rasterize:_artImageView1];
            }];
        } else if (slide.arts.count > 1) {
            [_artImageView1 setHidden:YES];
            [_artImageView2 setHidden:NO];
            [_artImageView3 setHidden:NO];
            
            Art *art2 = (Art*)slide.arts[0];
            [_artImageView2 sd_setImageWithURL:[NSURL URLWithString:art2.photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView2 setArt:art2];
                [self rasterize:_artImageView2];
            }];
            Art *art3 = (Art*)slide.arts[1];
            [_artImageView3 sd_setImageWithURL:[NSURL URLWithString:art3.photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView3 setArt:art3];
                [self rasterize:_artImageView3];
            }];
            
        } else {
            [_artImageView1 setImage:nil];
            [_artImageView2 setImage:nil];
            [_artImageView3 setImage:nil];
        }
    } else {
        // no slide, this means this is a new slide prompt cell
        [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
        [_addPrompt setFont:[UIFont fontWithName:kLatoHairline size:50]];
        [_addPrompt setHidden:NO];
        [_addPrompt setTextColor:[UIColor colorWithWhite:1 alpha:.4]];
        [_addPrompt setNumberOfLines:0];
        [_slideNumberLabel setText:@""];
        [_artImageView1 setImage:nil];
        [_artImageView2 setImage:nil];
        [_artImageView3 setImage:nil];
    }
}

- (void)rasterize:(WFInteractiveImageView*)imageView {
    imageView.layer.shouldRasterize = YES;
    imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (UIImage *)getRasterizedImageCopy {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
