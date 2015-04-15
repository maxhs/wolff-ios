//
//  WFUsersViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFUsersViewController.h"
#import "WFAppDelegate.h"
#import "WFUtilities.h"
#import "User+helper.h"
#import "WFAlert.h"
#import "WFNewUserCell.h"
#import "WFUserCollectionCell.h"

@interface WFUsersViewController () <UITextFieldDelegate> {
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
    NSMutableOrderedSet *_users;
    NSMutableOrderedSet *_filteredUsers;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    UITextField *userNameField;
    UIButton *noUsersButton;
    UIBarButtonItem *noUsersBarButton;
    UIBarButtonItem *spacerBarButton;
    UIImageView *navBarShadowView;
}

@end

@implementation WFUsersViewController

static NSString * const reuseIdentifier = @"UserCell";

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
    
    _users = [NSMutableOrderedSet orderedSetWithArray:[User MR_findAllSortedBy:@"firstName" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
    _filteredUsers = [NSMutableOrderedSet orderedSet];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    noUsersButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [noUsersButton.titleLabel setFont:[UIFont fontWithName:kMuseoSans size:12]];
    [noUsersButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [noUsersButton addTarget:self action:@selector(noUsersToggled) forControlEvents:UIControlEventTouchUpInside];
    [noUsersButton setFrame:CGRectMake(0, 0, 170.f, 44.f)];
    if (self.ownerMode){
        [noUsersButton setTitle:@"NO OWNERS" forState:UIControlStateNormal];
    } else {
        [noUsersButton setTitle:@"NO USERS" forState:UIControlStateNormal];
    }
    noUsersBarButton = [[UIBarButtonItem alloc] initWithCustomView:noUsersButton];
    spacerBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerBarButton.width = 23.f;
    [self adjustUnknownButtonColor];
    self.navigationItem.rightBarButtonItems = @[saveButton, spacerBarButton, noUsersBarButton];
    
    [self registerKeyboardNotifications];
    topInset = self.navigationController.navigationBar.frame.size.height; // matches the navigation bar
    [self setUpSearch];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)noUsersToggled {
    [self.selectedUsers removeAllObjects];
    [self adjustUnknownButtonColor];
    [_collectionView reloadData];
}

- (void)adjustUnknownButtonColor {
    if (self.selectedUsers.count){
        [noUsersButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [noUsersButton setTitleColor:kSaffronColor forState:UIControlStateNormal];
    }
}

- (void)loadUsersWithSearch:(NSString*)searchString {
    if (!loading && searchString.length){
        loading = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (searchString.length){
            [parameters setObject:searchString forKey:@"search"];
        }
        [manager POST:@"users/search" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading users: %@",responseObject);
            for (id dict in [responseObject objectForKey:@"users"]){
                User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!user){
                    user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [user populateFromDictionary:dict];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                _users = [NSMutableOrderedSet orderedSetWithArray:[User MR_findAllSortedBy:@"firstName" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
                [self filterContentForSearchText:searchString scope:nil];
                loading = NO;
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WFAlert show:@"Sorry, something went wrong while trying to fetch user info.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            NSLog(@"Failed to load users: %@",error.description);
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
        return _filteredUsers.count + 1;
    } else {
        return _users.count + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredUsers.count) || (indexPath.row == _users.count)){
        WFNewUserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewUserCell" forIndexPath:indexPath];
        if (editing){
            [cell.userPrompt setHidden:YES];
            [cell.nameLabel setHidden:NO];
            [cell.nameTextField setHidden:NO];
            [cell.nameTextField setPlaceholder:@"+  add a new user"];
            
            if (searchText.length){
                [cell.nameTextField setText:searchText];
            } else {
                [cell.nameTextField setText:@""];
            }
            [cell.createButton setHidden:NO];
            [cell.createButton addTarget:self action:@selector(createUser) forControlEvents:UIControlEventTouchUpInside];
            [cell.nameTextField becomeFirstResponder];
            [cell.nameTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [cell.nameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.nameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
            cell.nameTextField.delegate = self;
            userNameField = cell.nameTextField;
        } else {
            [cell.createButton setHidden:YES];
            [cell.userPrompt setHidden:NO];
            [cell.nameTextField setHidden:YES];
            [cell.nameLabel setHidden:YES];
            if (searchText.length){
                [cell.userPrompt setText:[NSString stringWithFormat:@"+  add \"%@\"",searchText]];
            } else {
                [cell.userPrompt setText:@"+  add a new user"];
            }
        }
        return cell;
    } else {
        WFUserCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        User * user = searching ? _filteredUsers[indexPath.item] : _users[indexPath.item];
        [cell configureForUser:user];
        if ([self.selectedUsers containsObject:user]){
            [cell.checkmark setHidden:NO];
        } else {
            [cell.checkmark setHidden:YES];
        }
        return cell;
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(width/4,width/4);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredUsers.count) || (indexPath.row == _users.count)){
        [self toggleEditMode];
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        User *user = searching ? _filteredUsers[indexPath.item] : _users[indexPath.item];
        if ([self.selectedUsers containsObject:user]){
            [self.selectedUsers removeObject:user];
        } else {
            [self.selectedUsers addObject:user];
        }
        
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    [self adjustUnknownButtonColor];
}

- (void) toggleEditMode {
    editing = editing ? NO : YES ;
}

#pragma mark - Search Methods
- (void)setUpSearch {
    [_noSearchResultsLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    [_noSearchResultsLabel setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
    [_noSearchResultsLabel setText:@"No search results..."];
    [_noSearchResultsLabel setHidden:YES];
    
    [self.searchBar setPlaceholder:@"Search for a user"];
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
        [self loadUsersWithSearch:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (text.length) {
        [_filteredUsers removeAllObjects];
        for (User *user in _users){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if ([predicate evaluateWithObject:user.fullName]) {
                [_filteredUsers addObject:user];
            }
        }
        if (!_filteredUsers.count) {
            [self loadUsersWithSearch:text];
        }
    } else {
        _filteredUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:_users];
    }
    
    [self.collectionView reloadData];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItems = @[doneButton,spacerBarButton,noUsersBarButton];
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if (self.searchBar.isFirstResponder){
        [self.searchBar resignFirstResponder];
    }
    self.navigationItem.rightBarButtonItems = @[saveButton,spacerBarButton,noUsersBarButton];
}

- (void)createUser {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.view endEditing:YES];
    });
    
    User *user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    
    NSArray *wordsAndEmptyStrings = [userNameField.text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *words = [wordsAndEmptyStrings filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    user.firstName = words[0];
    user.lastName = words[1];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:user.fullName forKey:@"name"];
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",user.fullName]];
    [manager POST:@"users" parameters:@{@"user":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a new user: %@",responseObject);
        if ([responseObject objectForKey:@"user"]){
            [user populateFromDictionary:[responseObject objectForKey:@"user"]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        //add the new user to the selection
        [self.selectedUsers addObject:user];
        [ProgressHUD dismiss];
        
        if (self.userDelegate && [self.userDelegate respondsToSelector:@selector(usersSelected:)]){
            [self.userDelegate usersSelected:self.selectedUsers];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while. Please try again soon." withTime:2.7f];
        [ProgressHUD dismiss];
        NSLog(@"Failed to create a new user: %@",error.description);
    }];
}

- (void)save {
    if (self.ownerMode){
        if (self.selectedUsers.count){
            if (self.userDelegate && [self.userDelegate respondsToSelector:@selector(lightTableOwnersSelected:)]){
                [self.userDelegate lightTableOwnersSelected:self.selectedUsers];
            }
        } else {
            if (self.userDelegate && [self.userDelegate respondsToSelector:@selector(lightTableOwnersSelected:)]){
                [self.userDelegate lightTableOwnersSelected:nil];
            }
        }
    } else {
        if (self.selectedUsers.count){
            if (self.userDelegate && [self.userDelegate respondsToSelector:@selector(usersSelected:)]){
                [self.userDelegate usersSelected:self.selectedUsers];
            }
        } else {
            if (self.userDelegate && [self.userDelegate respondsToSelector:@selector(usersSelected:)]){
                [self.userDelegate usersSelected:nil];
            }
        }
    }
    [self dismiss];
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