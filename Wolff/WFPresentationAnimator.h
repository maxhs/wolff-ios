//
//  WFPresentationAnimator.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/4/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFPresentationAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
