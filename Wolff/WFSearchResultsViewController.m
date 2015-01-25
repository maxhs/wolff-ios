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
    NSMutableArray *_filteredPhotos;
    NSMutableOrderedSet *selectedPhotos;
    NSString *searchText;
    BOOL searching;
}

@end

@implementation WFSearchResultsViewController

@synthesize photos = _photos;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    [_collectionView setBackgroundColor:[UIColor blackColor]];
    
    // show full tile view if it's a real search
    if (!_photos.count && _shouldShowTiles){
        _photos = [Photo MR_findAllInContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    }
    _filteredPhotos = [NSMutableArray arrayWithArray:_photos];
    selectedPhotos = [NSMutableOrderedSet orderedSet];
    
    if (_shouldShowTiles) {
        // this means we're looking at search results on the "make slideshow" view
        [_collectionView setHidden:NO];
        [_tableView setHidden:YES];
        [_noResultsPrompt setTextColor:[UIColor colorWithWhite:1 alpha:.7]];
        [self.collectionView reloadData];
    } else {
        // this means we're actually looking at selected slides
        [_noResultsPrompt setText:@"Nothing selected..."];
        [_collectionView setHidden:YES];
        [_tableView setHidden:NO];
        [_noResultsPrompt setTextColor:[UIColor colorWithWhite:0 alpha:.7]];
        [self.tableView reloadData];
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
                [searchTextField setBackgroundColor:[UIColor colorWithWhite:0 alpha:.77]];
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
    if (_photos.count == 0){
        [_noResultsPrompt setHidden:NO];
        return 0;
    } else {
        [_noResultsPrompt setHidden:YES];
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    } else {
        if (searching){
            return _filteredPhotos.count;
        } else {
            return _photos.count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        
        WFSearchOptionsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchOptionsCell" forIndexPath:indexPath];
        [cell.textLabel setText:@""];
        [cell.lightTableButton setHidden:NO];
        [cell.lightTableButton addTarget:self action:@selector(lightTableAction) forControlEvents:UIControlEventTouchUpInside];
        //[cell.lightTableButton setImage:[UIImage imageNamed:@"whitePlus"] forState:UIControlStateNormal];
        [cell.lightTableButton setTitle:@"+   light table" forState:UIControlStateNormal];
        [cell.lightTableButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.f]];
        
        [cell.slideShowButton setHidden:NO];
        //[cell.slideShowButton setImage:[UIImage imageNamed:@"whitePlus"] forState:UIControlStateNormal];
        [cell.slideShowButton setTitle:@"+   slideshow" forState:UIControlStateNormal];
        [cell.slideShowButton addTarget:self action:@selector(slideShowAction) forControlEvents:UIControlEventTouchUpInside];
        [cell.slideShowButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.02f]];
        
        [cell.clearSelectedButton setHidden:NO];
        [cell.cancelXImageView setImage:[UIImage imageNamed:@"remove"]];
        CGPoint centerPoint = cell.clearSelectedButton.center;
        CGRect cancelXFrame = cell.cancelXImageView.frame;
        cancelXFrame.origin.x = centerPoint.x-40;
        [cell.cancelXImageView setFrame:cancelXFrame];
        [cell.clearSelectedButton setTitle:@"   clear" forState:UIControlStateNormal];
        [cell.clearSelectedButton addTarget:self action:@selector(removeSelected) forControlEvents:UIControlEventTouchUpInside];
        [cell.clearSelectedButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.04f]];
        return cell;
    } else {
        WFSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];
        Photo *photo = searching ? _filteredPhotos[indexPath.row] : _photos[indexPath.row];
        [cell configureForPhoto:photo];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        return 44.f;
    } else {
        return 80.f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        Photo *photo = _photos[indexPath.row];
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(searchDidSelectPhoto:)]) {
            [self.searchDelegate searchDidSelectPhoto:photo];
        }
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
        return _filteredPhotos.count;
    } else {
        return _photos.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    if (searching && _filteredPhotos.count == 0){
        [_noResultsPrompt setHidden:NO];
    } else {
        [_noResultsPrompt setHidden:YES];
    }
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFSearchCollectionCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SearchCollectionCell" forIndexPath:indexPath];
    Photo *photo = searching ? _filteredPhotos[indexPath.row] : _photos[indexPath.row];
    [cell configureForPhoto:photo];
    if ([selectedPhotos containsObject:photo]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Photo *photo;
    if (searching){
        photo = _filteredPhotos[indexPath.row];
    } else {
        photo = _photos[indexPath.row];
    }
    if ([selectedPhotos containsObject:photo]){
        [selectedPhotos removeObject:photo];
    } else {
        [selectedPhotos addObject:photo];
    }
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(searchDidSelectPhoto:)]) {
        [self.searchDelegate searchDidSelectPhoto:photo];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(endSearch)]){
        [self.searchDelegate endSearch];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    if (!text.length){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.searchBar setText:@""];
            searching = NO;
            [_noResultsPrompt setHidden:YES];
            _shouldShowTiles ? [self.collectionView reloadData] : [self.tableView reloadData];
        });
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
    [_filteredPhotos removeAllObjects];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    //NSLog(@"search text: %@",text);
    if (text.length) {
        searching = YES;
        [_filteredPhotos removeAllObjects];
        for (Photo *photo in _photos){
            Art *art = photo.art;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:art.title]) {
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.artistsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.locationsToSentence]){
                [_filteredPhotos addObject:photo];
            }
        }
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
