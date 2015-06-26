//
//  WFComparisonViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFComparisonViewController : UIViewController

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *slideMetadataContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *metadataCollectionView;
@property (strong, nonatomic) NSMutableOrderedSet *photos;

@end
