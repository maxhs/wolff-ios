//
//  WFUsersViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WFSelectUsersDelegate <NSObject>
- (void)lightTableOwnersSelected:(NSOrderedSet*)selectedOwners;
- (void)usersSelected:(NSOrderedSet*)selectedUsers;
@end

@interface WFUsersViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *noSearchResultsLabel;
@property (strong, nonatomic) NSMutableOrderedSet *selectedUsers;
@property (weak, nonatomic) id<WFSelectUsersDelegate>userDelegate;
@property BOOL ownerMode;
@end
