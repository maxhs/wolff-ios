//
//  WFNewTagCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFNewTagCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *tagPrompt;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@end
