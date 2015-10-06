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

@protocol WFPlaySlideshowDelegate <NSObject>
- (void)willDismissPlayer;
@end

@interface WFSlideshowViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet WFGesturableCollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *slideMetadataContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *metadataCollectionView;
@property (strong, nonatomic) Slideshow *slideshow;
@property (strong, nonatomic) NSArray *photos; // comparison mode
@property (strong, nonatomic) NSNumber *startIndex;
@property (weak, nonatomic) id <WFPlaySlideshowDelegate> playSlideshowDelegate;
- (void)dismiss;

@end
