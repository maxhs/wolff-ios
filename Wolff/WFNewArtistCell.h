//
//  WFNewArtistCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFNewArtistCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *artistPrompt;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UITextField *birthYearTextField;
@property (weak, nonatomic) IBOutlet UITextField *deathYearTextField;

@end
