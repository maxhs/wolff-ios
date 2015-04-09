//
//  WFTagCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tag+helper.h"

@interface WFTagCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *tagCoverImage;
@property (weak, nonatomic) IBOutlet UILabel *tagNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;

- (void)configureForTag:(Tag*)tag;

@end
