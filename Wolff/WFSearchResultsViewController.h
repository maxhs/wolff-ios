//
//  WFSearchResultsViewController.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"

@protocol WFSearchDelegate <NSObject>
- (void)searchDidSelectArt:(Art *)art;
- (void)endSearch;
@end

@interface WFSearchResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *noResultsPrompt;
@property (strong, nonatomic) NSMutableArray *arts;
@property (weak, nonatomic) id<WFSearchDelegate> searchDelegate;
@property BOOL shouldShowSearchBar;
@property BOOL shouldShowTiles;

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope;

@end
