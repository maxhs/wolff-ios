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
#import "WFAlert.h"
#import "WFUtilities.h"

@interface WFSearchResultsViewController () <UISearchBarDelegate, WFLightTablesDelegate, WFSlideshowsDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    CGFloat keyboardHeight;
    CGFloat topInset;
    NSMutableArray *_photos;
    NSMutableOrderedSet *_filteredPhotos;
    NSMutableOrderedSet *selected;
    NSString *searchText;
    BOOL landscape;
    BOOL searching;
    BOOL loading;
    BOOL noResults;
    UIBarButtonItem *lightTableButton;
    UIBarButtonItem *slideshowButton;
    UIButton *clearButton;
    UIBarButtonItem *clearBarButton;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *cancelButton;
    UIImageView *navBarShadowView;
}

@end

@implementation WFSearchResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if (SYSTEM_VERSION >= 8.f){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenHeight(); height = screenWidth();
    }

    [self.tableView setBackgroundColor:[UIColor clearColor]];
    self.tableView.rowHeight = 80.f;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    
    if (self.selectedPhotos){
        _photos = self.selectedPhotos.array.mutableCopy;
    } else {
        NSPredicate *photoPredicate = [NSPredicate predicateWithFormat:@"privatePhoto != %@ AND art.privateArt != %@",@YES, @YES];
        _photos = [Photo MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:photoPredicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    }
    if (self.slideshowPhotos.count){
        selected = self.slideshowPhotos;
    } else {
        selected = [NSMutableOrderedSet orderedSet];
    }
    _filteredPhotos = [NSMutableOrderedSet orderedSetWithArray:_photos];
    
    if (_shouldShowTiles) { // this means we're looking at search results on the "make slideshow" view
        [self.collectionView setHidden:NO];
        [self.tableView setHidden:YES];
        [_noResultsPrompt setTextColor:[UIColor colorWithWhite:1 alpha:.7]];
        [self.collectionView reloadData];
        [_noResultsPrompt setText:kNoSearchResults];
    } else { // this means we're actually looking at selected slides
        [self setPreferredContentSize:CGSizeMake(420, _originalPopoverHeight)];
        [_noResultsPrompt setText:@"Nothing selected..."];
        [self.collectionView setHidden:YES];
        [self.tableView setHidden:NO];
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
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    if (IDIOM == IPAD){
        topInset = 44.f; //the height of the search bar container
        [self.navigationItem setLeftBarButtonItems:@[lightTableButton, flexibleSpace1, slideshowButton, flexibleSpace2, clearBarButton]];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self.collectionView setBackgroundColor:[UIColor blackColor]];
    } else {
        
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
        [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
        [backgroundToolbar setTranslucent:YES];
        [self.tableView setBackgroundView:backgroundToolbar];
        
        topInset = self.navigationController.navigationBar.frame.size.height;
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:.14]];
        [self.collectionView setBackgroundColor:[UIColor blackColor]];
        dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = dismissButton;
        cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
        if (_shouldShowSearchBar){
            self.navigationItem.titleView = self.searchBar;
        }
        if (!_shouldShowTiles) {
            [self.navigationItem setRightBarButtonItems:@[lightTableButton, flexibleSpace1, slideshowButton, flexibleSpace2, clearBarButton]];
        }
    }
    
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self registerKeyboardNotifications];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.searchBar.delegate = self;
    navBarShadowView.hidden = YES;
    
    if (_shouldShowSearchBar){
        [self.searchBarContainerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.47]];
        
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
        if (IDIOM == IPAD){
            [self.navigationController setNavigationBarHidden:YES animated:NO];
        } else {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
    } else {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _noResultsPrompt.center = self.collectionView.center;
    landscape = self.view.frame.size.width > self.view.frame.size.height ? YES : NO;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_photos.count == 0 && !searching){
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
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
        vc.slideshowsDelegate = self;
    }
}

- (void)lightTableSelected:(LightTable *)l {
    LightTable *lightTable;
    if (l){
        lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    if (!lightTable || [lightTable.identifier isEqualToNumber:@0]){
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(newLightTableForSelected)]) {
            [self.searchDelegate newLightTableForSelected];
        }
    } else {
        if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(batchSelectForLightTable:)]) {
            [self.searchDelegate batchSelectForLightTable:lightTable];
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
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(slideshowSelected:)]) {
        [self.searchDelegate slideshowForSelected:nil];
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
    
    if (IDIOM != IPAD){
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .23 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self dismiss];
        });
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    width = size.width; height = size.height;
    landscape = size.width > size.height ? YES : NO;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (IDIOM != IPAD){
            [self.collectionView reloadData];
            [self.tableView reloadData];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(100,100);
    } else {
        return CGSizeMake(width/3, width/3);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    if (searching && _filteredPhotos.count == 0){
        [self.noResultsPrompt setHidden:NO];
    } else {
        [self.noResultsPrompt setHidden:YES];
    }
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredPhotos.count;
    } else {
        return _photos.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFSearchCollectionCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SearchCollectionCell" forIndexPath:indexPath];
    Photo *photo = searching ? _filteredPhotos[indexPath.row] : _photos[indexPath.row];
    [cell configureForPhoto:photo];
    [cell.checkmark setHidden:[selected containsObject:photo] ? NO : YES ];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Photo *photo;
    if (searching){
        photo = _filteredPhotos[indexPath.row];
    } else {
        photo = _photos[indexPath.row];
    }
    if ([selected containsObject:photo]){
        [selected removeObject:photo];
    } else {
        [selected addObject:photo];
    }
    if (selected.count){
        [dismissButton setImage:[UIImage imageNamed:@"left"]];
    } else {
        [dismissButton setImage:[UIImage imageNamed:@"remove"]];
    }
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(searchDidSelectPhoto:)]) {
        [self.searchDelegate searchDidSelectPhoto:photo];
    }
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue *keyboardValue = keyboardInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
                         self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
                         self.navigationItem.rightBarButtonItem = cancelButton;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
                         self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
                         self.navigationItem.rightBarButtonItem = nil;
                     }
                     completion:NULL];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    [self.searchBar resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    noResults = NO;
    searching = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.searchDelegate && [self.searchDelegate respondsToSelector:@selector(endSearch)]){
        [self.searchDelegate endSearch];
    }
}

- (void)searchWithString:(NSString*)searchString{
    if (!loading && !noResults){
        loading = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if (searchString.length) {
            [parameters setObject:searchString forKey:@"search"];
        } else {
            return;
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        [_noResultsPrompt setText:@"Searching the full Wölff catalog..."];
        [manager GET:@"photos" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success searching from search reuslts view controller: %@",responseObject);
            if ([responseObject objectForKey:@"photos"] && [[responseObject objectForKey:@"photos"] count]){
                for (NSDictionary *dict in [responseObject objectForKey:@"photos"]) {
                    Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!photo){
                        photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [photo populateFromDictionary:dict];
                    [_photos addObject:photo];
                    if (searching){
                        [_filteredPhotos addObject:photo];
                    }
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    if (_shouldShowTiles){
                        [self.collectionView reloadData];
                    } else {
                        [self.tableView reloadData];
                    }
                    [ProgressHUD dismiss];
                    loading = NO;
                }];
            } else {
                [_noResultsPrompt setText:kNoSearchResults];
                loading = NO;
                if (searchString.length > 7){
                    noResults = YES;
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to search from split view: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while attempting to search. Please try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
        }];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (noResults){
        
    } else {
        [ProgressHUD show:@"Searching..."];
        [self searchWithString:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    if (!text.length){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.searchBar setText:@""];
            noResults = NO;
            searching = NO;
            [_noResultsPrompt setHidden:YES];
            _shouldShowTiles ? [self.collectionView reloadData] : [self.tableView reloadData];
        });
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self endSearch];
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    searchText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self filterContentForSearchText:searchText scope:nil];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
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
            } else if ([predicate evaluateWithObject:art.user.fullName]){
                [_filteredPhotos addObject:photo];
            }
        }
        if (_filteredPhotos.count == 0){
            [self searchWithString:text];
        } else {
            noResults = NO;
        }
    }
    
    if (_shouldShowTiles) {
        [self.collectionView reloadData];
    } else {
        [self.tableView reloadData];
    }
}

- (void)endSearch {
    [self.searchBar resignFirstResponder]; //have to manually resign the first responder here
    [self.searchBar setText:@""];
    [self.view endEditing:YES];
    searching = NO;
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [_filteredPhotos removeAllObjects];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (IDIOM == IPAD){
        [UIView animateWithDuration:.23 animations:^{
            [self.view setAlpha:0.0];
        }];
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
