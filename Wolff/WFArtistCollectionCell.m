//
//  WFArtistCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFArtistCollectionCell.h"
#import "Constants.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Photo+helper.h"

@implementation WFArtistCollectionCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_artistCoverImage setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_artistCoverImage setAlpha:0.0];
}

- (void)configureForArtist:(Artist *)artist {
    NSString *yearString;
    if (![artist.birthYear isEqualToNumber:@0] && ![artist.deathYear isEqualToNumber:@0]){
        yearString = [NSString stringWithFormat:@"%@ - %@",artist.birthYear, artist.deathYear];
    } else if (artist.birthYear && ![artist.birthYear isEqualToNumber:@0]){
        yearString = [NSString stringWithFormat:@"%@",artist.birthYear];
    } else if (artist.deathYear && ![artist.deathYear isEqualToNumber:@0]){
        yearString = [NSString stringWithFormat:@"%@",artist.deathYear];
    }
    
    NSMutableAttributedString *attributedNameString = [[NSMutableAttributedString alloc] initWithString:artist.name attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]}];
    
    NSAttributedString *attributedYearString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@)",yearString] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]}];
    
    if (yearString.length){
        [attributedNameString appendAttributedString:attributedYearString];
    }
    
    [_artistNameLabel setAttributedText:attributedNameString];
    Photo *coverPhoto = artist.photos.firstObject;
    if (coverPhoto.slideImageUrl.length){
        [_artistCoverImage setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:coverPhoto.slideImageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [_artistCoverImage setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [_artistCoverImage setImage:image];
            if (response){
                [UIView animateWithDuration:kFastAnimationDuration animations:^{
                    [_artistCoverImage setAlpha:1.0];
                }];
            } else {
                [_artistCoverImage setAlpha:1.0];
            }
        } failure:NULL];
        
    } else {
        [_artistCoverImage setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
        [_artistCoverImage setImage:nil];
        [_artistCoverImage setAlpha:1.0];
    }
}

@end
