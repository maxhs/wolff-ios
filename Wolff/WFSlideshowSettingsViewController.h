//
//  WFSlideshowSettingsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/2/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Presentation+helper.h"

@protocol WFSlideshowSettingsDelegate <NSObject>

- (void)deletePresentation;
- (void)updatePresentation;

@end

@interface WFSlideshowSettingsViewController : UITableViewController
@property (strong, nonatomic) Presentation *presentationId;
@property (weak, nonatomic) id<WFSlideshowSettingsDelegate>settingsDelegate;

@end
