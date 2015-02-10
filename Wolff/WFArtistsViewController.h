//
//  WFArtistsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WFSelectArtistsDelegate <NSObject>
- (void)artistsSelected:(NSOrderedSet*)selectedArtists;
@end

@interface WFArtistsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *noSearchResultsLabel;
@property (strong, nonatomic) NSMutableOrderedSet *selectedArtists;
@property (weak, nonatomic) id<WFSelectArtistsDelegate>artistDelegate;

@end
