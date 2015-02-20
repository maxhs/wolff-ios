//
//  WFIconsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/13/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WFSelectIconsDelegate <NSObject>
- (void)iconsSelected:(NSOrderedSet*)selectedIcons;
@end

@interface WFIconsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *noSearchResultsLabel;
@property (strong, nonatomic) NSMutableOrderedSet *selectedIcons;
@property (weak, nonatomic) id<WFSelectIconsDelegate>iconsDelegate;
@end
