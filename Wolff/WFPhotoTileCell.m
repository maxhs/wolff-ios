//
//  WFPhotoTileCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFPhotoTileCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Constants.h"

@implementation WFPhotoTileCell

- (void)configureForPhoto:(Photo*)photo {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:photo.thumbImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    [self.artImageView setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
        [self.artImageView setImage:image];
        if (response){
            [UIView animateWithDuration:kFastAnimationDuration animations:^{
                [self.artImageView setAlpha:1.0];
            }];
        } else {
            [self.artImageView setAlpha:1.0];
        }
    } failure:NULL];
}
@end
