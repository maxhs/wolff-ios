//
//  WFPresentationSlideCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"

@interface WFPresentationSlideCell : UICollectionViewCell

- (void)configureForSlide:(Slide*)slide;
@end
