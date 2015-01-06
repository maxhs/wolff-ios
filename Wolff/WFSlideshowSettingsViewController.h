//
//  WFSlideshowSettingsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/2/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slideshow+helper.h"

@protocol WFSlideshowSettingsDelegate <NSObject>

- (void)deleteSlideshow;
- (void)updateSlideshow;

@end

@interface WFSlideshowSettingsViewController : UITableViewController
@property (strong, nonatomic) Slideshow *slideshowId;
@property (weak, nonatomic) id<WFSlideshowSettingsDelegate>settingsDelegate;

@end
