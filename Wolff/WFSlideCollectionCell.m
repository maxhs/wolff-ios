//
//  WFSlideCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideCollectionCell.h"
#import "Art+helper.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFSlideCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    _slideBackgroundView.layer.cornerRadius = 13.f;
    _slideBackgroundView.clipsToBounds = YES;
    [_slideBackgroundView setBackgroundColor:[UIColor whiteColor]];
    
    _slideBackgroundView.layer.borderColor = [UIColor colorWithWhite:.77 alpha:1].CGColor;
    _slideBackgroundView.layer.borderWidth = .5f;
}

- (void)configureForSlide:(Slide *)slide {
    [_captionLabel setText:slide.caption];
    if (slide.arts.count == 1){
        Art *art = slide.arts.firstObject;
        [_singleArtImageView sd_setImageWithURL:[NSURL URLWithString:art.photo.mediumImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
        }];
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
