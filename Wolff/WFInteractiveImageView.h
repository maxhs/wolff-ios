//
//  WFInteractiveImageView.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/2/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"

@protocol WFImageViewDelegate <NSObject>

@optional
- (void)longPressGesture:(id)imageView;
@end

@interface WFInteractiveImageView : UIImageView

@property (strong, nonatomic) Photo *photo;
@property (weak, nonatomic) id<WFImageViewDelegate>imageViewDelegate;
- (id)initWithImage:(UIImage*)image andPhoto:(Photo*)photo;
- (id)initWithFrame:(CGRect)frame andPhoto:(Photo*)photo;

@end
