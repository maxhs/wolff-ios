//
//  WFSlideCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideCollectionCell.h"
#import "Constants.h"
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
    [super awakeFromNib];
    
    [_slideContainerView setBackgroundColor:kSlideBackgroundColor];
    _slideContainerView.layer.cornerRadius = 14.f;
    _slideContainerView.layer.shouldRasterize = YES;
    
    _slideContainerView.layer.backgroundColor = kSlideBackgroundColor.CGColor;
    _slideContainerView.layer.shadowColor = [UIColor colorWithWhite:.5 alpha:1].CGColor;
    _slideContainerView.layer.shadowOpacity = .4f;
    _slideContainerView.layer.shadowOffset = CGSizeMake(1.3f, 1.7f);
    _slideContainerView.layer.shadowRadius = 1.3f;
    
    _slideContainerView.clipsToBounds = NO;
}

- (void)configureForSlide:(Slide *)slide {
    if (slide.photos.count == 1){
        Photo *photo = slide.photos.firstObject;
        [_singleArtImageView sd_setImageWithURL:[NSURL URLWithString:photo.slideImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
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
