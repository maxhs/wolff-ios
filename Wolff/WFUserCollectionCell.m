//
//  WFUserCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFUserCollectionCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Constants.h"

@implementation WFUserCollectionCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_userProfileImage setContentMode:UIViewContentModeScaleAspectFit];
    [_userProfileImage setAlpha:0.0];
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
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:user.avatarLarge] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        [_userProfileImage setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
            [_userProfileImage setImage:image];
            if (response){
                [UIView animateWithDuration:kFastAnimationDuration animations:^{
                    [_userProfileImage setAlpha:1.0];
                }];
            } else {
                [_userProfileImage setAlpha:1.0];
            }
        } failure:NULL];
       
    } else {
        [_userProfileImage setImage:[UIImage imageNamed:@"transparentIconWhite"]];
        [_userProfileImage setAlpha:1.0];
    }
}

@end
