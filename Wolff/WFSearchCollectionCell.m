//
//  WFSearchCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSearchCollectionCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Constants.h"

@implementation WFSearchCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.imageView setAlpha:0.0];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
    //self.imageView.clipsToBounds = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView setAlpha:0.0];
}

- (UIImage *)getRasterizedImageCopy {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)configureForPhoto:(Photo *)photo {
    if (photo.thumbImageUrl.length){
        [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.thumbImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [self.imageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [self.imageView setImage:image];
            if (response){
                [UIView animateWithDuration:kFastAnimationDuration animations:^{
                    [self.imageView setAlpha:1.0];
                }];
            } else {
                [self.imageView setAlpha:1.0];
            }
        } failure:NULL];
        
    } else {
        [self setBackgroundColor:[UIColor clearColor]];
    }
}
@end
