//
//  WFLoginAnimator.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface WFLoginAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
