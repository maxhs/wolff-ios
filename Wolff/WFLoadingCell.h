//
//  WFLoadingCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 7/19/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFLoadingCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;
@end
