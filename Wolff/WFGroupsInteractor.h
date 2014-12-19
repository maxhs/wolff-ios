//
//  WFGroupsInteractor.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WFTablesViewController.h"

@interface WFGroupsInteractor : UIPercentDrivenInteractiveTransition <WFTablesViewControllerPanTarget>

-(id)initWithParentViewController:(UIViewController *)viewController;

@property (nonatomic, readonly) UIViewController *parentViewController;

-(void)presentMenu; // Presents the menu non-interactively

@end
