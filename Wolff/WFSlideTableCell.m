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
    [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [_artImageView1 setContentMode:UIViewContentModeScaleAspectFit];
    [_artImageView2 setContentMode:UIViewContentModeScaleAspectFit];
    [_artImageView3 setContentMode:UIViewContentModeScaleAspectFit];
    
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_removeButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThin] size:0]];
    [_removeButton setTitle:@"Remove" forState:UIControlStateNormal];
    [_moveButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansThin] size:0]];
    [_moveButton setTitle:@"Move" forState:UIControlStateNormal];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
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
        //clear the background
        [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];
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
