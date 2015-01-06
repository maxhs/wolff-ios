//
//  WFSlideMetadataViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"
#import "Slide+helper.h"
#import "Slideshow+helper.h"

@interface WFSlideMetadataViewController : UIViewController

@property (strong, nonatomic) NSOrderedSet *photos;
@property (strong, nonatomic) Slide *slide;
@property (strong, nonatomic) Slideshow *slideshow;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void)dismiss;

@end
