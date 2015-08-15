//
//  WFIconsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/13/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFIconsViewController.h"
#import "WFAppDelegate.h"
#import "WFUtilities.h"
#import "WFAlert.h"
#import "WFIconCollectionCell.h"
#import "WFNewIconCell.h"

@interface WFIconsViewController () <WFSelectIconsDelegate, UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    BOOL searching;
    BOOL editing;
    BOOL loading;
    BOOL noResults;
    CGFloat width;
    CGFloat height;
    CGFloat topInset;
    NSString *searchText;
    NSMutableOrderedSet *_icons;
    NSMutableOrderedSet *_filteredIcons;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UITextField *iconTextField;
    UIButton *noIconsButton;
    UIBarButtonItem *unknownBarButton;
    UIBarButtonItem *spacerBarButton;
    UIImageView *navBarShadowView;
}

@end

@implementation WFIconsViewController

static NSString * const reuseIdentifier = @"IconCell";

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
    
    _icons = [NSMutableOrderedSet orderedSetWithArray:[Icon MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
    _filteredIcons = [NSMutableOrderedSet orderedSet];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    
    noIconsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [noIconsButton.titleLabel setFont:[UIFont fontWithName:kMuseoSans size:12]];
    [noIconsButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [noIconsButton addTarget:self action:@selector(iconUnknownToggled) forControlEvents:UIControlEventTouchUpInside];
    [noIconsButton setFrame:CGRectMake(0, 0, 170.f, 44.f)];
    [noIconsButton setTitle:@"NO ICONOGRAPHY" forState:UIControlStateNormal];
    unknownBarButton = [[UIBarButtonItem alloc] initWithCustomView:noIconsButton];
    spacerBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerBarButton.width = -23.f;
    [self adjustUnknownButtonColor];
    
    if (IDIOM == IPAD){
        self.navigationItem.rightBarButtonItems = @[saveButton, spacerBarButton, unknownBarButton];
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    
    [self registerKeyboardNotifications];
    topInset = self.navigationController.navigationBar.frame.size.height;
    [self setUpSearch];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)iconUnknownToggled {
    [self.selectedIcons removeAllObjects];
    [self adjustUnknownButtonColor];
    [self.collectionView reloadData];
}

- (void)adjustUnknownButtonColor {
    if (self.selectedIcons.count){
        [noIconsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [noIconsButton setTitleColor:kSaffronColor forState:UIControlStateNormal];
    }
}

- (void)loadIconsWithSearch:(NSString*)searchString {
    if (!loading && !noResults){
        searching = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (searchString.length){
            [parameters setObject:searchString forKey:@"search"];
        }
        loading = YES;
        [manager POST:@"icons/search" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading icons: %@",responseObject);
            if ([responseObject objectForKey:@"icons"] && [[responseObject objectForKey:@"icons"] count]){
                noResults = NO;
                for (id dict in [responseObject objectForKey:@"icons"]){
                    Icon *icon = [Icon MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!icon){
                        icon = [Icon MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [icon populateFromDictionary:dict];
                    [_filteredIcons addObject:icon];
                    [_icons addObject:icon];
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [ProgressHUD dismiss];
                    [_collectionView reloadData];
                    loading = NO;
                }];
                
            } else {
                noResults = YES;
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WFAlert show:@"Sorry, something went wrong while trying to fetch icon info.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            loading = NO;
            NSLog(@"Failed to load icons: %@",error.description);
        }];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    _icons = [NSMutableOrderedSet orderedSetWithArray:[Icon MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredIcons.count + 1;
    } else {
        return _icons.count + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredIcons.count) || (indexPath.row == _icons.count)){
        WFNewIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewIconCell" forIndexPath:indexPath];
        if (editing){
            [cell.prompt setHidden:YES];
            [cell.label setHidden:NO];
            [cell.iconNameTextField setHidden:NO];
            if (searchText.length){
                [cell.prompt setText:[NSString stringWithFormat:@"+  add \"%@\"",searchText]];
            } else {
                [cell.prompt setText:@"+  add a new iconography"];
            }
            if (searchText.length){
                [cell.iconNameTextField setText:searchText];
            } else {
                [cell.iconNameTextField setText:@""];
            }
            [cell.createButton setHidden:NO];
            [cell.createButton addTarget:self action:@selector(createicon) forControlEvents:UIControlEventTouchUpInside];
            [cell.iconNameTextField becomeFirstResponder];
            [cell.iconNameTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [cell.iconNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.iconNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [cell.iconNameTextField setReturnKeyType:UIReturnKeyDone];
            cell.iconNameTextField.delegate = self;
            iconTextField = cell.iconNameTextField;
            [iconTextField becomeFirstResponder];
        } else {
            [cell.prompt setHidden:NO];
            [cell.iconNameTextField setHidden:YES];
            [cell.label setHidden:YES];
            if (searchText.length){
                [cell.prompt setText:[NSString stringWithFormat:@"+  add \"%@\"",searchText]];
            } else {
                [cell.prompt setText:@"+  add a new iconography"];
            }
            [cell.createButton setHidden:YES];
        }
        return cell;
    } else {
        WFIconCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        Icon * icon = searching ? _filteredIcons[indexPath.item] : _icons[indexPath.item];
        [cell configureForIcon:icon];
        if ([self.selectedIcons containsObject:icon]){
            [cell.checkmark setHidden:NO];
        } else {
            [cell.checkmark setHidden:YES];
        }
        return cell;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == iconTextField && [string isEqualToString:@"\n"]) {
        [self createicon];
    }
    return YES;
}

- (void)iconsSelected:(NSOrderedSet *)selectedicons {
    
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(width/2,height/4);
    } else {
        return CGSizeMake(width,height/4);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredIcons.count) || (indexPath.row == _icons.count)){
        [self toggleEditMode];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        Icon *icon = searching ? _filteredIcons[indexPath.item] : _icons[indexPath.item];
        if ([self.selectedIcons containsObject:icon]){
            [self.selectedIcons removeObject:icon];
        } else {
            [self.selectedIcons addObject:icon];
        }
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
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
    searching = NO;
    noResults = NO;
    [_noSearchResultsLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    [_noSearchResultsLabel setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
    [_noSearchResultsLabel setText:@"No search results..."];
    [_noSearchResultsLabel setHidden:YES];
    
    [self.searchBar setPlaceholder:@"Search iconography"];
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
    if (searchBar.text.length && !noResults){
        [ProgressHUD show:@"Searching..."];
        [self loadIconsWithSearch:searchBar.text];
    } else {
        [self.view endEditing:YES];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (text.length) {
        [_filteredIcons removeAllObjects];
        for (Icon *icon in _icons){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if ([predicate evaluateWithObject:icon.name]) {
                [_filteredIcons addObject:icon];
            }
        }
        if (_filteredIcons.count == 0){
            [self loadIconsWithSearch:text];
        } else {
            noResults = NO;
        }
    } else {
        _filteredIcons = [NSMutableOrderedSet orderedSetWithOrderedSet:_icons];
    }
    
    [self.collectionView reloadData];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItems = @[spacerBarButton,unknownBarButton];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if (self.searchBar.isFirstResponder){
        [self.searchBar resignFirstResponder];
    }
    self.navigationItem.rightBarButtonItems = @[saveButton,spacerBarButton,unknownBarButton];
}

- (void)createicon {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.view endEditing:YES];
    });
    
    Icon *icon = [Icon MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    icon.name = iconTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:icon.name forKey:@"name"];
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",icon.name]];
    [manager POST:@"icons" parameters:@{@"icon":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success creating a new icon: %@",responseObject);
        if ([responseObject objectForKey:@"icon"]){
            [icon populateFromDictionary:[responseObject objectForKey:@"icon"]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        //add the new icon to the selection
        [self.selectedIcons addObject:icon];
        [ProgressHUD dismiss];
        
        if (self.iconsDelegate && [self.iconsDelegate respondsToSelector:@selector(iconsSelected:)]){
            [self.iconsDelegate iconsSelected:self.selectedIcons];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while. Please try again soon." withTime:2.7f];
        [ProgressHUD dismiss];
        NSLog(@"Failed to create a new icon: %@",error.description);
    }];
}

- (void)save {
    if (self.selectedIcons.count){
        
        if (self.iconsDelegate && [self.iconsDelegate respondsToSelector:@selector(iconsSelected:)]){
            [self.iconsDelegate iconsSelected:self.selectedIcons];
        }
        [self dismiss];
        
    } else {
        if (self.iconsDelegate && [self.iconsDelegate respondsToSelector:@selector(iconsSelected:)]){
            [self.iconsDelegate iconsSelected:nil];
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
