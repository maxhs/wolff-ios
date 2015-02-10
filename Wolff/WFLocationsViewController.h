//
//  WFLocationsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WFSelectLocationsDelegate <NSObject>
- (void)locationsSelected:(NSOrderedSet*)selectedLocations;
@end

@interface WFLocationsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *noSearchResultsLabel;
@property (strong, nonatomic) NSMutableOrderedSet *selectedLocations;
@property (weak, nonatomic) id<WFSelectLocationsDelegate>locationDelegate;
@end
