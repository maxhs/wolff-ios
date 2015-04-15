//
//  WFUserCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFUserCollectionCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Constants.h"

@implementation WFUserCollectionCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_userProfileImage setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_userProfileImage setAlpha:0.0];
}

- (void)configureForUser:(User *)user {
    NSMutableAttributedString *attributedNameString = [[NSMutableAttributedString alloc] initWithString:user.fullName attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]}];
    
    NSAttributedString *attributedInstitutionString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%@)",user.institutionsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]}];
    
    if (user.institutionsToSentence.length){
        [attributedNameString appendAttributedString:attributedInstitutionString];
    }
    
    [_userNameLabel setAttributedText:attributedNameString];
    
    if (user.avatarLarge.length){
        [_userProfileImage setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
        [_userProfileImage sd_setImageWithURL:[NSURL URLWithString:user.avatarLarge] placeholderImage:nil options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:kFastAnimationDuration animations:^{
                [_userProfileImage setAlpha:1.0];
            }];
        }];
    } else {
        [_userProfileImage setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    }
}
@end
