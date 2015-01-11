//
//  WFSearchOptionsCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFSearchOptionsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *lightTableButton;
@property (weak, nonatomic) IBOutlet UIButton *slideShowButton;
@property (weak, nonatomic) IBOutlet UIButton *clearSelectedButton;
@property (weak, nonatomic) IBOutlet UIImageView *cancelXImageView;

@end
