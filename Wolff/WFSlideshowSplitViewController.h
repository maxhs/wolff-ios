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
@protocol WFCreateSlideshowDelegate <NSObject>
- (void)slideshowCreated:(Slideshow*)slideshow;
@end

@interface WFSlideshowSplitViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *lightBoxPlaceholderLabel;
@property (weak, nonatomic) id<WFCreateSlideshowDelegate> createSlideshowDelegate;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) NSNumber *slideshowId;
@property (strong, nonatomic) Slideshow *slideshow;

- (void)dismissMetadata;
@end
