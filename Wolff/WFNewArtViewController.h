//
//  WFNewArtViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFImagePickerController.h"

@interface WFNewArtViewController : UIViewController <WFImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void)dismiss;
@end
