//
//  WFLightTableTableCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFLightTableTableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end
