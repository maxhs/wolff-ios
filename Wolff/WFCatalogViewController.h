//
//  WFCatalogViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCatalogViewController : UIViewController

@property (strong, nonatomic) UIPopoverController *popover;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *searchBarContainer;
@property BOOL login;

- (void)dismissMetadata;
- (void)dismiss;
@end
