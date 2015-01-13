//
//  WFSlideshowViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slideshow+helper.h"
#import "WFGesturableCollectionView.h"

@interface WFSlideshowViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet WFGesturableCollectionView *collectionView;
@property (strong, nonatomic) Slideshow *slideshow;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property NSInteger startIndex;

- (void)dismiss;

@end
