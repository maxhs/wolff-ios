//
//  WFNewArtViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "WFImagePickerController.h"

@protocol WFNewArtDelegate <NSObject>

@optional
- (void)newArtAdded:(Art*)art;
- (void)failedToAddArt:(Art*)art;

@end
@interface WFNewArtViewController : UIViewController <WFImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<WFNewArtDelegate> artDelegate;
- (void)dismiss;
@end
