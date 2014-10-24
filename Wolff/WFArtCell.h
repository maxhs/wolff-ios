//
//  WFArtCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFArtCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *artImageView;
-(UIImage *)getRasterizedImageCopy;
@end
