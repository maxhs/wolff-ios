//
//  WFNewArtCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFNewArtCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *theSwitch;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
