//
//  WFInteractiveImageView.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/2/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"

@protocol WFImageViewDelegate <NSObject>

@optional
- (void)longPressGesture:(id)imageView;

@end

@interface WFInteractiveImageView : UIImageView

@property (strong, nonatomic) Art *art;
@property (weak, nonatomic) id<WFImageViewDelegate>imageViewDelegate;
- (id)initWithImage:(UIImage*)image andArt:(Art*)art;
- (id)initWithFrame:(CGRect)frame andArt:(Art*)art;

@end
