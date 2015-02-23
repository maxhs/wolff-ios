//
//  WFCardViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/20/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card+helper.h"

@protocol WFCardDelegate <NSObject>
-(void)addedCardWithId:(NSNumber*)cardId;
@end

@interface WFCardViewController : UIViewController
@property (weak, nonatomic) id<WFCardDelegate>cardDelegate;
@end
