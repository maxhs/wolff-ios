//
//  WFNewUserCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFNewUserCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *userPrompt;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@end
