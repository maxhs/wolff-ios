//
//  WFLightTableKeyCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/12/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFLightTableKeyCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@end
