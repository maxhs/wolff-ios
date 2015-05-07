//
//  WFProfileAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/24/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFProfileAnimator.h"
#import "Constants.h"
#import "WFProfileViewController.h"
#import "UIImage+ImageEffects.h"
#import "WFArtMetadataViewController.h"

@interface WFProfileAnimator (){
    BOOL iOS8;
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
}

@end
@implementation WFProfileAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
        mainScreen = CGRectMake(0, 0, height, width);
    }
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController, *toViewController;
    UIView *fromView, *toView;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (iOS8) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    if (self.presenting) {
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        CGRect startFrame;
        if (iOS8){
            startFrame = mainScreen;
            startFrame.origin.y += height;
        } else {
            startFrame = mainScreen;
            startFrame.origin.x += width;
        }
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toView.frame = mainScreen;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
        
        UINavigationController *nav = (UINavigationController*)toViewController;
        if ([nav.viewControllers.firstObject isKindOfClass:[WFArtMetadataViewController class]]){
            WFArtMetadataViewController *artvc = (WFArtMetadataViewController*)nav.viewControllers.firstObject;
            CGFloat offset = height/2-350;
            UITableView *metadataTableView = artvc.tableView;
            [metadataTableView setContentInset:UIEdgeInsetsMake(offset, 0, offset, 0)];
            [metadataTableView setContentOffset:CGPointMake(0, -offset)];
            int lowerBound = 1; int upperBound = 3;
            int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
            CGFloat xOffset = rndValue == 1 ? width : -width;
            
            CGRect metadataFrame;
            if (iOS8) {
                metadataFrame = CGRectMake(width/2-kMetadataWidth/2, 0, kMetadataWidth, height);
                CGRect metadataStartFrame = CGRectMake((width/2-kMetadataWidth/2)-xOffset, 0, kMetadataWidth, height);
                toView.frame = metadataStartFrame;
            } else {
                metadataFrame = CGRectMake(0, width/2-kMetadataWidth/2, height, kMetadataWidth);
                CGRect metadataStartFrame = CGRectMake(0, (width/2-kMetadataWidth/2), height, kMetadataWidth);
                toView.frame = metadataStartFrame;
            }
        }
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        CGRect endFrame;
        if (iOS8){
            endFrame = mainScreen;
            endFrame.origin.y = height;
        } else {
            endFrame = mainScreen;
            endFrame.origin.x = width;
        }
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromView.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
