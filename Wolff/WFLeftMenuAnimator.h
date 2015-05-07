//
//  WFLeftMenuAnimator.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/19/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface WFLeftMenuAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
