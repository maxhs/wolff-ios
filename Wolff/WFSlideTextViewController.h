//
//  WFSlideTextViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideText+helper.h"
#import "Slideshow+helper.h"

@interface WFSlideTextViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Slideshow *slideshow;
@property (strong, nonatomic) Slide *slide;
@property (strong, nonatomic) SlideText *slideText;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end
