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
    [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
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
    [_slideNumberLabel setText:[NSString stringWithFormat:@"%ld.",(long)number]];
    if (slide){
        [_addPrompt setHidden:YES];
        if (slide.photos.count == 1){
            [_artImageView1 setHidden:NO];
            [_artImageView2 setHidden:YES];
            [_artImageView3 setHidden:YES];
            Photo *photo = (Photo*)[slide.photos firstObject];
            [_artImageView1 sd_setImageWithURL:[NSURL URLWithString:photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView1 setPhoto:photo];
                [self rasterize:_artImageView1];
            }];
        } else if (slide.photos.count > 1) {
            [_artImageView1 setHidden:YES];
            [_artImageView2 setHidden:NO];
            [_artImageView3 setHidden:NO];
            
            Photo *photo2 = (Photo*)slide.photos[0];
            [_artImageView2 sd_setImageWithURL:[NSURL URLWithString:photo2.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView2 setPhoto:photo2];
                [self rasterize:_artImageView2];
            }];
            Photo *photo3 = (Photo*)slide.photos[1];
            [_artImageView3 sd_setImageWithURL:[NSURL URLWithString:photo3.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView3 setPhoto:photo3];
                [self rasterize:_artImageView3];
            }];
            
        } else {
            [_artImageView1 setImage:nil];
            [_artImageView2 setImage:nil];
            [_artImageView3 setImage:nil];
        }
    } else {
        // no slide, this means this is a new slide prompt cell
        [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
        [_addPrompt setFont:[UIFont fontWithName:kMuseoSansThin size:43]];
        [_addPrompt setHidden:NO];
        [_addPrompt setTextColor:[UIColor colorWithWhite:1 alpha:.23]];
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
