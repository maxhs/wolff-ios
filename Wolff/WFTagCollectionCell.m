//
//  WFTagCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFTagCollectionCell.h"
#import "Constants.h"
#import "Photo+helper.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation WFTagCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_tagNameLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_tagCoverImage setAlpha:0.0];
}

- (void)configureForTag:(Tag *)tag {
    NSMutableAttributedString *tagString;
    if (tag.name.length){
        tagString = [[NSMutableAttributedString alloc] initWithString:tag.name attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]}];
    } else {
        tagString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]}];
    }
    
    [_tagNameLabel setAttributedText:tagString];
    
    __block Photo *coverPhoto;
    [tag.arts enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
        if (tag.photos){
            coverPhoto = tag.photos.firstObject;
            *stop = YES;
        }
    }];
    if (coverPhoto.slideImageUrl.length){
        [_tagCoverImage setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:coverPhoto.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [_tagCoverImage setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [_tagCoverImage setImage:image];
            if (response){
                [UIView animateWithDuration:kFastAnimationDuration animations:^{
                    [_tagCoverImage setAlpha:1.0];
                }];
            } else {
                [_tagCoverImage setAlpha:1.0];
            }
        } failure:NULL];
    
    } else {
        [_tagCoverImage setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
        [_tagCoverImage setImage:nil];
        [_tagCoverImage setAlpha:1.0];
    }
}

@end
