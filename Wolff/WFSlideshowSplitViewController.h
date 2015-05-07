//
//  WFSlideshowSplitViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slideshow+helper.h"
#import "Slide+helper.h"
@protocol WFSlideshowDelegate <NSObject>
- (void)slideshowCreated:(Slideshow*)slideshow;
- (void)slideshow:(Slideshow*)slideshow droppedToLightTable:(LightTable*)lightTable;
- (void)shouldReloadSlideshows;
@end

@interface WFSlideshowSplitViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *lightBoxPlaceholderLabel;
@property (strong, nonatomic) Slideshow *slideshow;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) NSMutableOrderedSet *photos;
@property (strong, nonatomic) NSMutableOrderedSet *selectedPhotos;
@property (weak, nonatomic) id<WFSlideshowDelegate> slideshowDelegate;
- (void)dismissMetadata;
@end
