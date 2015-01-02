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

- (void)configureForSlide:(Slide *)slide {
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
