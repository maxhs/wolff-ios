//
//  WFSlideshowCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slideshow+helper.h"

@interface WFSlideshowCell : UITableViewCell <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *slideshowLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
- (void)configureForSlideshow:(Slideshow*)slideshow;
@end
