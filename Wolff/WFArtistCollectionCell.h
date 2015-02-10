//
//  WFArtistCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Artist+helper.h"

@interface WFArtistCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *artistCoverImage;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;

- (void)configureForArtist:(Artist*)artist;
@end
