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
#import "SlideText+helper.h"

@implementation WFSlideTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:.17]];
    [_slideContainerView setBackgroundColor:[UIColor blackColor]];
    [_slideNumberLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [_artImageView1 setContentMode:UIViewContentModeScaleAspectFit];
    [_artImageView2 setContentMode:UIViewContentModeScaleAspectFit];
    [_artImageView3 setContentMode:UIViewContentModeScaleAspectFit];
    
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_slideTextLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLight] size:0]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_slideTextLabel setHidden:YES];
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
        if (slide.photoSlides.count == 1){
            [_artImageView1 setHidden:NO];
            [_artImageView2 setHidden:YES];
            [_artImageView3 setHidden:YES];
            PhotoSlide *photoSlide = slide.photoSlides.firstObject;
            [_artImageView1 sd_setImageWithURL:[NSURL URLWithString:photoSlide.photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView1 setPhoto:photoSlide.photo];
                [self rasterize:_artImageView1];
            }];
        } else if (slide.photoSlides.count > 1) {
            [_artImageView1 setHidden:YES];
            [_artImageView2 setHidden:NO];
            [_artImageView3 setHidden:NO];
            
            PhotoSlide *photoSlide = slide.photoSlides[0];
            [_artImageView2 sd_setImageWithURL:[NSURL URLWithString:photoSlide.photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView2 setPhoto:photoSlide.photo];
                [self rasterize:_artImageView2];
            }];
            PhotoSlide *photoSlide1 = slide.photoSlides[1];
            [_artImageView3 sd_setImageWithURL:[NSURL URLWithString:photoSlide1.photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [_artImageView3 setPhoto:photoSlide1.photo];
                [self rasterize:_artImageView3];
            }];
            
        } else {
            if (slide.slideTexts.count){
                SlideText *slideText = slide.slideTexts.firstObject;
                [_slideTextLabel setText:slideText.body];
                [_slideTextLabel setHidden:NO];
            }
            [_artImageView1 setImage:nil];
            [_artImageView2 setImage:nil];
            [_artImageView3 setImage:nil];
        }
        [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];  // clear the background
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
