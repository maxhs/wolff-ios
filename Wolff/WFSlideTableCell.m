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

@implementation WFSlideTableCell

- (void)awakeFromNib {
    [self setBackgroundColor:[UIColor blackColor]];
    [_slideContainerView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
    [_slideNumberLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_artImageView1 setBackgroundColor:[UIColor colorWithWhite:.5 alpha:1]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForSlide:(Slide *)slide withSlideNumber:(NSInteger)number {
    [_slideNumberLabel setText:[NSString stringWithFormat:@"%ld",(long)number]];
    if (slide.arts.count == 1){
        [_artImageView1 setHidden:NO];
        [_artImageView2 setHidden:YES];
        [_artImageView3 setHidden:YES];
        [_artImageView1 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)[slide.arts firstObject] photo] mediumImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        }];
    } else if (slide.arts.count > 1) {
        [_artImageView1 setHidden:YES];
        [_artImageView2 setHidden:NO];
        [_artImageView3 setHidden:NO];
        NSLog(@"slide arts: %@",slide.arts);
        [_artImageView2 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)[slide.arts firstObject] photo] mediumImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
        
        [_artImageView3 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)slide.arts[1] photo] mediumImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
        
    } else {
        [_artImageView1 setImage:nil];
        [_artImageView2 setImage:nil];
        [_artImageView3 setImage:nil];
    }
}

- (UIImage *)getRasterizedImageCopy {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
