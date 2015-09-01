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
#import <AFNetworking/UIImageView+AFNetworking.h>
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
            [_artImageView1 setPhoto:photoSlide.photo]; // have a photo reference
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photoSlide.photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
            [_artImageView1 setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
                [_artImageView1 setImage:image];
                if (response){
                    [UIView animateWithDuration:kFastAnimationDuration animations:^{
                        [_artImageView1 setAlpha:1.0];
                    }];
                } else {
                    [_artImageView1 setAlpha:1.0];
                }
            } failure:NULL];
        
        } else if (slide.photoSlides.count > 1) {
            [_artImageView1 setHidden:YES];
            [_artImageView2 setHidden:NO];
            [_artImageView3 setHidden:NO];
            
            PhotoSlide *photoSlide2 = slide.photoSlides[0];
            [_artImageView2 setPhoto:photoSlide2.photo];
            NSURLRequest *urlRequest2 = [NSURLRequest requestWithURL:[NSURL URLWithString:photoSlide2.photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
            [_artImageView2 setImageWithURLRequest:urlRequest2 placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
                [_artImageView2 setImage:image];
                if (response){
                    [UIView animateWithDuration:kFastAnimationDuration animations:^{
                        [_artImageView2 setAlpha:1.0];
                    }];
                } else {
                    [_artImageView2 setAlpha:1.0];
                }
            } failure:NULL];
            
            PhotoSlide *photoSlide3 = slide.photoSlides[1];
            [_artImageView3 setPhoto:photoSlide3.photo];
            NSURLRequest *urlRequest3 = [NSURLRequest requestWithURL:[NSURL URLWithString:photoSlide3.photo.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
            [_artImageView3 setImageWithURLRequest:urlRequest3 placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
                [_artImageView3 setImage:image];
                if (response){
                    [UIView animateWithDuration:kFastAnimationDuration animations:^{
                        [_artImageView3 setAlpha:1.0];
                    }];
                } else {
                    [_artImageView3 setAlpha:1.0];
                }
            } failure:NULL];
            
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
