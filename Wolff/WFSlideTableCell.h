//
//  WFSlideTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"
#import "WFInteractiveImageView.h"

@interface WFSlideTableCell : UITableViewCell <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *slideNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *addPrompt;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIButton *moveButton;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView1;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView2;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView3;

- (void)configureForSlide:(Slide*)slide withSlideNumber:(NSInteger)number;
- (UIImage *)getRasterizedImageCopy;

@end
