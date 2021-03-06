//
//  WFLocationsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLocationsViewController.h"
#import "WFAppDelegate.h"
#import "Constants.h"
#import "WFLocationCollectionCell.h"
#import "WFNewLocationCell.h"
#import "WFAlert.h"
#import "WFUtilities.h"
#import "WFTracking.h"

@interface WFLocationsViewController () <UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    NSString *searchText;
    BOOL searching;
    BOOL loading;
    BOOL noResults;
    NSMutableOrderedSet *_filteredLocations;
    NSMutableOrderedSet *_locations;
    UIBarButtonItem *dismissButton;
    UIButton *locationUnknownButton;
    UIBarButtonItem *clearLocationBarButton;
    UITextField *locationNameTextField;
    UITextField *countryTextField;
    UITextField *cityTextField;
    UITextField *stateTextField;
    CGFloat topInset;
    UIImageView *navBarShadowView;
}
@end

@implementation WFLocationsViewController

static NSString * const reuseIdentifier = @"LocationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    width = screenWidth();
    height = screenHeight();
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    _filteredLocations = [NSMutableOrderedSet orderedSet];
    _locations = [NSMutableOrderedSet orderedSetWithArray:[Location MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];

    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    locationUnknownButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [locationUnknownButton.titleLabel setFont:[UIFont fontWithName:kMuseoSans size:12]];
    
    [locationUnknownButton addTarget:self action:@selector(locationUnknownToggled) forControlEvents:UIControlEventTouchUpInside];
    [locationUnknownButton setFrame:CGRectMake(0, 0, 170.f, 44.f)];
    [locationUnknownButton setTitle:@"CLEAR LOCATION" forState:UIControlStateNormal];
    clearLocationBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(locationUnknownToggled)];
    
    [self registerKeyboardNotifications];
    topInset = self.navigationController.navigationBar.frame.size.height;
    [self setUpSearch];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    self.navigationItem.rightBarButtonItem = clearLocationBarButton;
    [self adjustLocationButtonColor];
    
    [WFTracking trackEvent:@"Locations" withProperties:nil];
}

- (void)locationUnknownToggled {
    [self.selectedLocations removeAllObjects];
    [_collectionView reloadData];
    [self adjustLocationButtonColor];
}

- (void)adjustLocationButtonColor {
    if (self.selectedLocations.count){
        [locationUnknownButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [locationUnknownButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.f]];
    } else {
        [locationUnknownButton setTitleColor:kSaffronColor forState:UIControlStateNormal];
        [locationUnknownButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)loadLocationsWithSearch:(NSString *)searchString {
    if (!loading && searchString.length && !noResults){
        loading = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (searchString.length){
            [parameters setObject:searchString forKey:@"search"];
        }
        [manager POST:@"locations/search" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading locations: %@",responseObject);
            if ([responseObject objectForKey:@"locations"]){
                NSDictionary *locationsDict = [responseObject objectForKey:@"locations"];
                if (locationsDict.count){
                    for (id dict in locationsDict){
                        Location *location = [Location MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                        if (!location){
                            location = [Location MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
                        }
                        [location populateFromDictionary:dict];
                    }
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        _locations = [NSMutableOrderedSet orderedSetWithArray:[Location MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
                        [self filterContentForSearchText:searchText scope:nil];
                        [ProgressHUD dismiss];
                        loading = NO;
                    }];
                } else {
                    noResults = YES;
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WFAlert show:@"Sorry, something went wrong while trying to fetch location info.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            NSLog(@"Failed to load locations: %@",error.description);
        }];
    }
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredLocations.count + 1;
    } else {
        return _locations.count + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredLocations.count) || (indexPath.row == _locations.count)){
        WFNewLocationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewLocationCell" forIndexPath:indexPath];
        [cell.locationPrompt setHidden:YES];
        [cell.nameLabel setHidden:NO];
        [cell.cityLabel setHidden:NO];
        [cell.countryLabel setHidden:NO];
        
        [cell.countryTextField setHidden:NO];
        [cell.countryTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [cell.countryTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [cell.countryTextField setReturnKeyType:UIReturnKeyDone];
    
        [cell.nameTextField becomeFirstResponder];
        [cell.nameTextField setPlaceholder:kAddLocationPlaceholder];
        [cell.nameTextField setHidden:NO];
        [cell.nameTextField setReturnKeyType:UIReturnKeyNext];
        [cell.nameTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [cell.nameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [cell.nameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        cell.nameTextField.delegate = self;
        
        [cell.cityTextField setHidden:NO];
        [cell.cityTextField setReturnKeyType:UIReturnKeyNext];
        [cell.cityTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
        [cell.cityTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [cell.cityTextField setPlaceholder:@"City"];
        
        [cell.createButton setHidden:NO];
        [cell.createButton addTarget:self action:@selector(createLocation) forControlEvents:UIControlEventTouchUpInside];
        
        (searchText.length) ? [cell.nameTextField setText:searchText] : [cell.nameTextField setText:@""];
        
        cityTextField = cell.cityTextField;
        stateTextField = cell.stateTextField;
        countryTextField = cell.countryTextField;
        locationNameTextField = cell.nameTextField;
//        } else {
//            [cell.locationPrompt setHidden:NO];
//            [cell.nameTextField setHidden:YES];
//            [cell.nameLabel setHidden:YES];
//            [cell.countryTextField setHidden:YES];
//            [cell.countryLabel setHidden:YES];
//            if (searchText.length){
//                [cell.locationPrompt setText:[NSString stringWithFormat:@"+ add \"%@\"",searchText]];
//            } else {
//                [cell.locationPrompt setText:@"+  add a new location"];
//            }
//            [cell.createButton setHidden:YES];
//        }
        return cell;
    } else {
        WFLocationCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        Location * location = searching ? _filteredLocations[indexPath.item] : _locations[indexPath.item];
        [cell configureForLocation:location];
        if ([self.selectedLocations containsObject:location]){
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
        if ((searching && indexPath.item == _filteredLocations.count) || indexPath.item == _locations.count){
            return CGSizeMake(width/2,height/3);
        } else {
            return CGSizeMake(width/4,height/3);
        }
    } else {
        return CGSizeMake(collectionView.frame.size.width,height/4);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Location *location = searching ? _filteredLocations[indexPath.item] : _locations[indexPath.item];
    [self.selectedLocations removeAllObjects];
    [self.selectedLocations addObject:location];
    [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    //[collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    [self adjustLocationButtonColor];
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
    
    [self.searchBar setPlaceholder:IDIOM == IPAD ? @"Search for the piece's *current* location" : @"Current location..."];
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setTextColor:[UIColor whiteColor]];
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
            searchTextField.keyboardAppearance = UIKeyboardAppearanceDark;
            [searchTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            break;
        }
    }
    self.navigationItem.titleView = self.searchBar;
    self.searchBar.delegate = self;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searching = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (searchBar.text.length){
        [ProgressHUD show:@"Searching..."];
        [self loadLocationsWithSearch:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (text.length) {
        [_filteredLocations removeAllObjects];
        for (Location *location in _locations){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if ([predicate evaluateWithObject:location.name]) {
                [_filteredLocations addObject:location];
            } else if ([predicate evaluateWithObject:location.city]) {
                [_filteredLocations addObject:location];
            } else if ([predicate evaluateWithObject:location.state]) {
                [_filteredLocations addObject:location];
            } else if ([predicate evaluateWithObject:location.country]) {
                [_filteredLocations addObject:location];
            }
        }
        
        if (!_filteredLocations.count) {
            [self loadLocationsWithSearch:text];
        } else {
            noResults = NO;
        }
    } else {
        _filteredLocations = [NSMutableOrderedSet orderedSetWithOrderedSet:_locations];
    }
    
    [self.collectionView reloadData];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == locationNameTextField && [string isEqualToString:@"\n"]) {
        [countryTextField becomeFirstResponder];
        return NO;
    } else if (textField == countryTextField && locationNameTextField.text.length && [string isEqualToString:@"\n"]) {
        [self createLocation];
        return NO;
    }
    return YES;
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if (self.searchBar.isFirstResponder){
        [self.searchBar resignFirstResponder];
    }
}

- (void)createLocation {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.view endEditing:YES];
    });
    
    Location *location = [Location MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    location.name = locationNameTextField.text;
    location.city = cityTextField.text;
    location.state = stateTextField.text;
    location.country = countryTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (location.name.length){
        [parameters setObject:location.name forKey:@"name"];
    }
    if (location.city.length){
        [parameters setObject:location.city forKey:@"city"];
    }
    if (location.country.length){
        [parameters setObject:location.country forKey:@"country"];
    }
    if (location.state.length){
        [parameters setObject:location.state forKey:@"state"];
    }
    
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",location.name]];
    [manager POST:@"locations" parameters:@{@"location":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a new location: %@",responseObject);
        if ([responseObject objectForKey:@"location"]){
            [location populateFromDictionary:[responseObject objectForKey:@"location"]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        //add the new location to the selection
        [self.selectedLocations addObject:location];
        [ProgressHUD dismiss];
        
        if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationsSelected:)]){
            [self.locationDelegate locationsSelected:self.selectedLocations];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while. Please try again soon." withTime:2.7f];
        [ProgressHUD dismiss];
        NSLog(@"Failed to create a new location: %@",error.description);
    }];
}

- (void)save {
    if (self.selectedLocations.count){
        
        if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationsSelected:)]){
            [self.locationDelegate locationsSelected:self.selectedLocations];
        }
        [self dismiss];
        
    } else {
        if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationsSelected:)]){
            [self.locationDelegate locationsSelected:nil];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
