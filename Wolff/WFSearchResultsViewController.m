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
#import "WFSlideshowsViewController.h"
#import "WFLightTablesViewController.h"

@interface WFSearchResultsViewController () <UISearchBarDelegate, WFLightTablesDelegate, WFSlideshowDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    NSMutableArray *_filteredPhotos;
    NSMutableOrderedSet *selectedPhotos;
    NSString *searchText;
    BOOL searching;
    UIToolbar *backgroundToolbar;
    UIBarButtonItem *lightTableButton;
    UIBarButtonItem *slideshowButton;
    UIButton *clearButton;
    UIBarButtonItem *clearBarButton;
}

@end

@implementation WFSearchResultsViewController

@synthesize photos = _photos;
@synthesize originalPopoverHeight = _originalPopoverHeight;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.rowHeight = 80.f;
    [_collectionView setBackgroundColor:[UIColor blackColor]];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
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
        [self setPreferredContentSize:CGSizeMake(420, _originalPopoverHeight)];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        [_noResultsPrompt setText:@"Nothing selected..."];
        [_collectionView setHidden:YES];
        [_tableView setHidden:NO];
        [_noResultsPrompt setTextColor:[UIColor colorWithWhite:0 alpha:.7]];
        [self.tableView reloadData];
    }

    [_noResultsPrompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
    
    lightTableButton  = [[UIBarButtonItem alloc] initWithTitle:@"+   light table" style:UIBarButtonItemStylePlain target:self action:@selector(lightTableAction)];
    [lightTableButton setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0], NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    UIBarButtonItem *flexibleSpace1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    slideshowButton  = [[UIBarButtonItem alloc] initWithTitle:@"+   slideshow" style:UIBarButtonItemStylePlain target:self action:@selector(slideShowAction)];
    [slideshowButton setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0], NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    UIBarButtonItem *flexibleSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearButton setFrame:CGRectMake(0, 0, 80.f, 44.f)];
    [clearButton setImage:[UIImage imageNamed:@"miniRemove"] forState:UIControlStateNormal];
    [clearButton setTitle:@"   clear" forState:UIControlStateNormal];
    [clearButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0]];
    [clearButton addTarget:self action:@selector(removeSelected) forControlEvents:UIControlEventTouchUpInside];
    [clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    clearBarButton = [[UIBarButtonItem alloc] initWithCustomView:clearButton];
    [self.navigationItem setLeftBarButtonItems:@[lightTableButton, flexibleSpace1, slideshowButton, flexibleSpace2, clearBarButton]];
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
    if (self.view.alpha != 1.0){
        [UIView animateWithDuration:.23 animations:^{
            [self.view setAlpha:1.0];
        }];
    }
    [self.navigationController setPreferredContentSize:CGSizeMake(420, _originalPopoverHeight)];
    
    //hide the navigation bar if there are no photos so that we can see the no photos prompt
    if (!_photos.count){
        [self.navigationController setNavigationBarHidden:YES];
    } else {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    [self.tableView reloadData];
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
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searching){
        return _filteredPhotos.count;
    } else {
        return _photos.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];
    Photo *photo = searching ? _filteredPhotos[indexPath.row] : _photos[indexPath.row];
    [cell configureForPhoto:photo];
    return cell;
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
    [self performSegueWithIdentifier:@"LightTables" sender:self];
}

- (void)slideShowAction {
    [self performSegueWithIdentifier:@"Slideshows" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"LightTables"]){
        WFLightTablesViewController *vc = [segue destinationViewController];
        vc.lightTableDelegate = self;
    } else if ([segue.identifier isEqualToString:@"Slideshows"]){
        WFSlideshowsViewController *vc = [segue destinationViewController];
        vc.slideshowDelegate = self;
    }
}

- (void)lightTableSelected:(NSNumber *)lightTableId {
    Table *lightTable;
    if ([lightTableId isEqualToNumber:@0]){
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(newLightTableForSelected)]) {
            [self.searchDelegate newLightTableForSelected];
        }
    } else {
        lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(lightTableForSelected:)]) {
            [self.searchDelegate lightTableForSelected:lightTable];
        }
    }
}

- (void)batchFavorite {
    NSLog(@"should be batch favoriting");
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(batchFavorite)]){
        [self.searchDelegate batchFavorite];
    }
}

- (void)newSlideshow {
    Slideshow *slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(slideshowSelected:)]) {
        [self.searchDelegate slideshowForSelected:slideshow];
    }
}

- (void)slideshowSelected:(Slideshow *)slideshow {
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(slideshowSelected:)]) {
        [self.searchDelegate slideshowForSelected:slideshow];
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

- (void)viewWillDisappear:(BOOL)animated {
    [UIView animateWithDuration:.23 animations:^{
        [self.view setAlpha:0.0];
    }];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
