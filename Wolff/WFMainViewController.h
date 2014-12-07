//
//  WFMainViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFMainViewController : UIViewController

@property (strong, nonatomic) UIPopoverController *popover;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property BOOL login;

- (void)dismissMetadata;
@end
