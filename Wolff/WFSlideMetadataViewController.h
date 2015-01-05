//
//  WFSlideMetadataViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"
#import "Presentation+helper.h"

@interface WFSlideMetadataViewController : UIViewController

@property (strong, nonatomic) NSOrderedSet *arts;
@property (strong, nonatomic) Slide *slide;
@property (strong, nonatomic) Presentation *presentation;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void)dismiss;

@end
