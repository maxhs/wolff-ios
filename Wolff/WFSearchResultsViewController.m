//
//  WFSearchResultsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSearchResultsViewController.h"
#import "WFAppDelegate.h"
#import "WFSearchResultsCell.h"
#import "WFSearchCollectionCell.h"
#import "WFSearchOptionsCell.h"

@interface WFSearchResultsViewController () <UISearchBarDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_filteredArts;
    NSMutableOrderedSet *selectedArt;
    NSString *searchText;
    BOOL searching;
}

@end

@implementation WFSearchResultsViewController

@synthesize arts = _arts;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    //[_tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:0]];
    _tableView.rowHeight = 80.f;
    [_collectionView setBackgroundColor:[UIColor blackColor]];
    
    // show full tile view if it's a real search
    if (!_arts.count && _shouldShowTiles){
        _arts = [Art MR_findAllInContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    }
    _filteredArts = [NSMutableArray arrayWithArray:_arts];
    selectedArt = [NSMutableOrderedSet orderedSet];
    
    if (_shouldShowTiles) {
        [_collectionView setHidden:NO];
        [_tableView setHidden:YES];
        [self.collectionView reloadData];
    } else {
        [_collectionView setHidden:YES];
        [_tableView setHidden:NO];
        [self.tableView reloadData];
    }
    
    if (_shouldShowTiles){
        [_noResultsPrompt setTextColor:[UIColor colorWithWhite:1 alpha:.7]];
    } else {
        [_noResultsPrompt setTextColor:[UIColor colorWithWhite:0 alpha:.7]];
    }
    [_noResultsPrompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.searchBar.delegate = self;
    searching = YES;
    if (_shouldShowSearchBar){
        if (_shouldShowTiles){
            // don't need to do anything, search bar is already visible for collection view
        } else {
            [self.tableView setTableHeaderView:self.searchBar];
        }
        [self.searchBar setHidden:NO];
        [self.searchBar setPlaceholder:@"Search the catalog"];
        
        //reset the search bar font
        for (id subview in [self.searchBar.subviews.firstObject subviews]){
            if ([subview isKindOfClass:[UITextField class]]){
                UITextField *searchTextField = (UITextField*)subview;
                [searchTextField setTextColor:[UIColor whiteColor]];
                [searchTextField setTintColor:[UIColor whiteColor]];
                [searchTextField setBackgroundColor:[UIColor colorWithWhite:0 alpha:.5]];
                [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
                searchTextField.keyboardAppearance = UIKeyboardAppearanceDark;
                break;
            }
        }
        [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
        [self.searchBar becomeFirstResponder];
    } else {
        [self.searchBar setHidden:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _noResultsPrompt.center = _collectionView.center;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_arts.count == 0){
        [_noResultsPrompt setHidden:NO];
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        return 1;
    } else {
        [_noResultsPrompt setHidden:YES];
        //[tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        if (searching){
            return _filteredArts.count;
        } else {
            return _arts.count;
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        WFSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];
        Art *art = searching ? _filteredArts[indexPath.row] : _arts[indexPath.row];
        [cell configureForArt:art];
        
        return cell;
    } else if (indexPath.section == 1) {
        WFSearchOptionsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchOptionsCell" forIndexPath:indexPath];
        [cell.textLabel setText:@""];
        [cell.lightTableButton setHidden:NO];
        [cell.lightTableButton addTarget:self action:@selector(lightTableAction) forControlEvents:UIControlEventTouchUpInside];
        [cell.lightTableButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
        [cell.lightTableButton setTitle:[NSString stringWithFormat:@" Light table with %d images",_arts.count] forState:UIControlStateNormal];
        [cell.lightTableButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.035f]];
        [cell.slideShowButton setHidden:NO];
        [cell.slideShowButton setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
        [cell.slideShowButton setTitle:[NSString stringWithFormat:@" slideshow with %d images",_arts.count] forState:UIControlStateNormal];
        [cell.slideShowButton addTarget:self action:@selector(slideShowAction) forControlEvents:UIControlEventTouchUpInside];
        [cell.slideShowButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.07f]];
        return cell;
    } else {
        WFSearchOptionsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RemoveSelectedCell" forIndexPath:indexPath];
        [cell.textLabel setText:@"Deselect all"];
        [cell.lightTableButton setHidden:YES];
        [cell.slideShowButton setHidden:YES];
        [cell.imageView setImage:[UIImage imageNamed:@"blackRemove"]];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        Art *art = _arts[indexPath.row];
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(searchDidSelectPhoto:)]) {
            [self.searchDelegate searchDidSelectPhoto:art.photo];
        }
    } else if (indexPath.section == 1){
        
    } else {
        [self removeSelected];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)lightTableAction {
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(lightTableFromSelected)]) {
        [self.searchDelegate lightTableFromSelected];
    }
}

- (void)slideShowAction {
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(slideShowFromSelected)]) {
        [self.searchDelegate slideShowFromSelected];
    }
}

- (void)removeSelected{
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(removeAllSelected)]) {
        [self.searchDelegate removeAllSelected];
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100,100);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredArts.count;
    } else {
        return _arts.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    if (_filteredArts.count == 0){
        [_noResultsPrompt setHidden:NO];
    } else {
        [_noResultsPrompt setHidden:YES];
    }
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFSearchCollectionCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SearchCollectionCell" forIndexPath:indexPath];
    Art *art = searching ? _filteredArts[indexPath.row] : _arts[indexPath.row];
    [cell configureForArt:art];
    if ([selectedArt containsObject:art]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Art *art = _filteredArts[indexPath.row];
    
    if ([selectedArt containsObject:art]){
        [selectedArt removeObject:art];
    } else {
        [selectedArt addObject:art];
    }
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(searchDidSelectPhoto:)]) {
        [self.searchDelegate searchDidSelectPhoto:art.photo];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(endSearch)]){
        [self.searchDelegate endSearch];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
    [self.tableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    searchText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:searchText scope:nil];
    return YES;
}

- (void)endSearch {
    //have to manually resign the first responder here
    [self.searchBar resignFirstResponder];
    [self.searchBar setText:@""];
    [self.view endEditing:YES];
    searching = NO;
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [_filteredArts removeAllObjects];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    NSLog(@"search text: %@",text);
    if (text.length) {
        [_filteredArts removeAllObjects];
        for (Art *art in _arts){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:art.title]) {
                [_filteredArts addObject:art];
            } else if ([predicate evaluateWithObject:art.artistsToSentence]){
                [_filteredArts addObject:art];
            } else if ([predicate evaluateWithObject:art.locationsToSentence]){
                [_filteredArts addObject:art];
            }
        }
    } else {
        _filteredArts = [NSMutableArray arrayWithArray:_arts];
    }
    if (_shouldShowTiles) {
        [self.collectionView reloadData];
    } else {
        [self.tableView reloadData];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
