//
//  WFArtistsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFArtistsViewController.h"
#import "WFArtistCollectionCell.h"
#import "WFNewArtistCell.h"
#import "WFAppDelegate.h"
#import "Constants.h"
#import "WFAlert.h"
#import "WFUtilities.h"

@interface WFArtistsViewController () <UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    BOOL loading;
    BOOL searching;
    BOOL editing;
    CGFloat width;
    CGFloat height;
    CGFloat topInset;
    NSString *searchText;
    NSMutableOrderedSet *_artists;
    NSMutableOrderedSet *_filteredArtists;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    UITextField *artistNameField;
    UIButton *artistUnknownButton;
    UIBarButtonItem *unknownBarButton;
    UIBarButtonItem *spacerBarButton;
    UIImageView *navBarShadowView;
}

@end

@implementation WFArtistsViewController

static NSString * const reuseIdentifier = @"ArtistCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    _artists = [NSMutableOrderedSet orderedSetWithArray:[Artist MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
    _filteredArtists = [NSMutableOrderedSet orderedSet];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    artistUnknownButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [artistUnknownButton.titleLabel setFont:[UIFont fontWithName:kMuseoSans size:12]];
    [artistUnknownButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [artistUnknownButton addTarget:self action:@selector(artistUnknownToggled) forControlEvents:UIControlEventTouchUpInside];
    [artistUnknownButton setFrame:CGRectMake(0, 0, 170.f, 44.f)];
    [artistUnknownButton setTitle:@"ARTIST UNKNOWN" forState:UIControlStateNormal];
    unknownBarButton = [[UIBarButtonItem alloc] initWithCustomView:artistUnknownButton];
    spacerBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerBarButton.width = 23.f;
    [self adjustUnknownButtonColor];
    self.navigationItem.rightBarButtonItems = @[saveButton, spacerBarButton, unknownBarButton];
    
    [self registerKeyboardNotifications];
    topInset = self.navigationController.navigationBar.frame.size.height; // matches the navigation bar
    [self setUpSearch];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)artistUnknownToggled {
    [self.selectedArtists removeAllObjects];
    [self adjustUnknownButtonColor];
    [_collectionView reloadData];
}

- (void)adjustUnknownButtonColor {
    if (self.selectedArtists.count){
        [artistUnknownButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [artistUnknownButton setTitleColor:kSaffronColor forState:UIControlStateNormal];
    }
}

- (void)loadArtistsWithSearch:(NSString*)searchString {
    if (!loading && searchString.length){
        loading = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (searchString.length){
            [parameters setObject:searchString forKey:@"search"];
        }
        [manager POST:@"artists/search" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading artists: %@",responseObject);
            for (id dict in [responseObject objectForKey:@"artists"]){
                Artist *artist = [Artist MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext    :[NSManagedObjectContext MR_defaultContext]];
                if (!artist){
                    artist = [Artist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [artist populateFromDictionary:dict];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                _artists = [NSMutableOrderedSet orderedSetWithArray:[Artist MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
                [self filterContentForSearchText:searchString scope:nil];
                loading = NO;
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WFAlert show:@"Sorry, something went wrong while trying to fetch artist info.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            NSLog(@"Failed to load artists: %@",error.description);
            loading = NO;
        }];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredArtists.count + 1;
    } else {
        return _artists.count + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredArtists.count) || (indexPath.row == _artists.count)){
        WFNewArtistCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewArtistCell" forIndexPath:indexPath];
        if (editing){
            [cell.artistPrompt setHidden:YES];
            [cell.nameLabel setHidden:NO];
            [cell.nameTextField setHidden:NO];
            [cell.nameTextField setPlaceholder:@"+  add a new artist"];
            
            if (searchText.length){
                [cell.nameTextField setText:searchText];
            } else {
                [cell.nameTextField setText:@""];
            }
            [cell.createButton setHidden:NO];
            [cell.createButton addTarget:self action:@selector(createArtist) forControlEvents:UIControlEventTouchUpInside];
            [cell.nameTextField becomeFirstResponder];
            [cell.nameTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [cell.nameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.nameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
            cell.nameTextField.delegate = self;
            artistNameField = cell.nameTextField;
        } else {
            [cell.createButton setHidden:YES];
            [cell.artistPrompt setHidden:NO];
            [cell.nameTextField setHidden:YES];
            [cell.nameLabel setHidden:YES];
            if (searchText.length){
                [cell.artistPrompt setText:[NSString stringWithFormat:@"+  add \"%@\"",searchText]];
            } else {
                [cell.artistPrompt setText:@"+  add a new artist"];
            }
        }
        return cell;
    } else {
        WFArtistCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        Artist * artist = searching ? _filteredArtists[indexPath.item] : _artists[indexPath.item];
        [cell configureForArtist:artist];
        if ([self.selectedArtists containsObject:artist]){
            [cell.checkmark setHidden:NO];
        } else {
            [cell.checkmark setHidden:YES];
        }
        return cell;
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(width/4,width/4);
    } else {
        return CGSizeMake(width/2,width/2);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredArtists.count) || (indexPath.row == _artists.count)){
        [self toggleEditMode];
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        Artist *artist = searching ? _filteredArtists[indexPath.item] : _artists[indexPath.item];
        if ([self.selectedArtists containsObject:artist]){
            [self.selectedArtists removeObject:artist];
        } else {
            [self.selectedArtists addObject:artist];
        }
        
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    [self adjustUnknownButtonColor];
}

- (void) toggleEditMode {
    editing = editing ? NO : YES ;
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark - Search Methods
- (void)setUpSearch {
    [_noSearchResultsLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    [_noSearchResultsLabel setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
    [_noSearchResultsLabel setText:@"No search results..."];
    [_noSearchResultsLabel setHidden:YES];
    
    [self.searchBar setPlaceholder:@"Search for an artist"];
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setTextColor:[UIColor whiteColor]];
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
            searchTextField.keyboardAppearance = UIKeyboardAppearanceDark;
            break;
        }
    }
    self.navigationItem.titleView = self.searchBar;
    self.searchBar.delegate = self;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (searchBar.text.length){
        [ProgressHUD show:@"Searching..."];
        [self loadArtistsWithSearch:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (text.length) {
        [_filteredArtists removeAllObjects];
        for (Artist *artist in _artists){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if ([predicate evaluateWithObject:artist.name]) {
                [_filteredArtists addObject:artist];
            }
        }
        if (!_filteredArtists.count) {
            [self loadArtistsWithSearch:text];
        }
    } else {
        _filteredArtists = [NSMutableOrderedSet orderedSetWithOrderedSet:_artists];
    }
    
    [self.collectionView reloadData];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItems = @[doneButton,spacerBarButton,unknownBarButton];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if (self.searchBar.isFirstResponder){
        [self.searchBar resignFirstResponder];
    }
    self.navigationItem.rightBarButtonItems = @[saveButton,spacerBarButton,unknownBarButton];
}

- (void)createArtist {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.view endEditing:YES];
    });
    
    Artist *artist = [Artist MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    artist.name = artistNameField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:artist.name forKey:@"name"];
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",artist.name]];
    [manager POST:@"artists" parameters:@{@"artist":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a new artst: %@",responseObject);
        if ([responseObject objectForKey:@"artist"]){
            [artist populateFromDictionary:[responseObject objectForKey:@"artist"]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        //add the new artist to the selection
        [self.selectedArtists addObject:artist];
        [ProgressHUD dismiss];
        
        if (self.artistDelegate && [self.artistDelegate respondsToSelector:@selector(artistsSelected:)]){
            [self.artistDelegate artistsSelected:self.selectedArtists];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while. Please try again soon." withTime:2.7f];
        [ProgressHUD dismiss];
        NSLog(@"Failed to create a new artist: %@",error.description);
    }];
}

- (void)save {
    if (self.selectedArtists.count){
        if (self.artistDelegate && [self.artistDelegate respondsToSelector:@selector(artistsSelected:)]){
            [self.artistDelegate artistsSelected:self.selectedArtists];
        }
        [self dismiss];
    } else {
        if (self.artistDelegate && [self.artistDelegate respondsToSelector:@selector(artistsSelected:)]){
            [self.artistDelegate artistsSelected:nil];
        }
        [self dismiss];
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
    CGFloat keyboardHeight = convertedKeyboardFrame.size.height;
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         _collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                         _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                     }
                     completion:NULL];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         _collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
                         _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
                     }
                     completion:NULL];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
