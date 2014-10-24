//
//  WFSlideTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFSlideTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *slideNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;

@end
