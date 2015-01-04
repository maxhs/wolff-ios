//
//  WFSlideshowViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Presentation+helper.h"

@interface WFSlideshowViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) Presentation *presentation;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;

- (void)dismiss;

@end
