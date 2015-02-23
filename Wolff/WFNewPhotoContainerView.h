//
//  WFNewPhotoContainerView.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/17/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"
#import "Art+helper.h"
#import "WFCreditTextField.h"

@interface WFNewPhotoContainerView : UIView

@property (strong, nonatomic) Photo *currentPhoto;
@property (strong, nonatomic) UIImageView *photoImageView;
@property (strong, nonatomic) UILabel *iconographyLabel;
@property (strong, nonatomic) UIButton *iconographyButton;
@property (strong, nonatomic) WFCreditTextField *creditTextField;
@property (strong, nonatomic) UILabel *creditLabel;

@end
