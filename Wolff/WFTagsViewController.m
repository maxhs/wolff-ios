//
//  WFTagsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFTagsViewController.h"
#import "WFAppDelegate.h"
#import "WFUtilities.h"
#import "WFAlert.h"
#import "WFNewTagCell.h"
#import "WFTagCollectionCell.h"

@interface WFTagsViewController () <UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL iOS8;
    CGFloat width;
    CGFloat height;
    NSString *searchText;
    BOOL searching;
    BOOL loading;
    BOOL editing;
    BOOL noResults;
    NSMutableOrderedSet *_filteredTags;
    NSMutableOrderedSet *_tags;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    UIButton *noTagsButton;
    UIBarButtonItem *noTagBarButton;
    UIBarButtonItem *spacerBarButton;
    UITextField *tagNameTextField;
    CGFloat topInset;
    UIImageView *navBarShadowView;
}
@end

@implementation WFTagsViewController

static NSString * const reuseIdentifier = @"TagCell";

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
    
    _filteredTags = [NSMutableOrderedSet orderedSet];
    _tags = [NSMutableOrderedSet orderedSetWithArray:[Tag MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
    
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    noTagsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [noTagsButton.titleLabel setFont:[UIFont fontWithName:kMuseoSans size:12]];
    [noTagsButton addTarget:self action:@selector(noTagsToggled) forControlEvents:UIControlEventTouchUpInside];
    [noTagsButton setFrame:CGRectMake(0, 0, 170.f, 44.f)];
    [noTagsButton setTitle:@"NO TAGS" forState:UIControlStateNormal];
    noTagBarButton = [[UIBarButtonItem alloc] initWithCustomView:noTagsButton];
    spacerBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerBarButton.width = 23.f;
    
    [self registerKeyboardNotifications];
    topInset = self.navigationController.navigationBar.frame.size.height;
    [self setUpSearch];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    if (IDIOM == IPAD){
        self.navigationItem.rightBarButtonItems = @[saveButton, spacerBarButton, noTagBarButton];
    } else {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    [self adjustTagButtonColor];
}

- (void)noTagsToggled {
    [self.selectedTags removeAllObjects];
    [_collectionView reloadData];
    [self adjustTagButtonColor];
}

- (void)adjustTagButtonColor {
    if (self.selectedTags.count){
        [noTagsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [noTagsButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.f]];
    } else {
        [noTagsButton setTitleColor:kSaffronColor forState:UIControlStateNormal];
        [noTagsButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)loadTagsWithSearch:(NSString *)searchString {
    if (!loading && searchString.length && !noResults){
        loading = YES;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (searchString.length){
            [parameters setObject:searchString forKey:@"search"];
        }
        [manager POST:@"tags/search" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading tags: %@",responseObject);
            if ([responseObject objectForKey:@"tags"]){
                NSDictionary *tagsDict = [responseObject objectForKey:@"tags"];
                if (tagsDict.count){
                    for (id dict in tagsDict){
                        Tag *tag = [Tag MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                        if (!tag){
                            tag = [Tag MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                        }
                        [tag populateFromDictionary:dict];
                    }
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        _tags = [NSMutableOrderedSet orderedSetWithArray:[Tag MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
                        [self filterContentForSearchText:searchText scope:nil];
                        [ProgressHUD dismiss];
                        loading = NO;
                    }];
                } else {
                    noResults = YES;
                }
            } else {
                [self.searchBar resignFirstResponder];
                noResults = YES;
                [ProgressHUD dismiss];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WFAlert show:@"Sorry, something went wrong while trying to fetch tag info.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            NSLog(@"Failed to load tags: %@",error.description);
        }];
    }
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredTags.count + 1;
    } else {
        return _tags.count + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredTags.count) || (indexPath.row == _tags.count)){
        WFNewTagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewTagCell" forIndexPath:indexPath];
        
        if (editing){
            [cell.tagPrompt setHidden:YES];
            [cell.nameLabel setHidden:NO];
            
            [cell.nameTextField becomeFirstResponder];
            [cell.nameTextField setPlaceholder:kAddTagPlaceholder];
            [cell.nameTextField setHidden:NO];
            [cell.nameTextField setReturnKeyType:UIReturnKeyNext];
            [cell.nameTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [cell.nameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.nameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
            cell.nameTextField.delegate = self;
            
            [cell.createButton setHidden:NO];
            [cell.createButton addTarget:self action:@selector(createTag) forControlEvents:UIControlEventTouchUpInside];
            
            (searchText.length) ? [cell.nameTextField setText:searchText] : [cell.nameTextField setText:@""];
        
            tagNameTextField = cell.nameTextField;
        } else {
            [cell.tagPrompt setHidden:NO];
            [cell.nameTextField setHidden:YES];
            [cell.nameLabel setHidden:YES];
            if (searchText.length){
                [cell.tagPrompt setText:[NSString stringWithFormat:@"+ add \"%@\"",searchText]];
            } else {
                [cell.tagPrompt setText:@"+  add a new tag"];
            }
            [cell.createButton setHidden:YES];
        }
        return cell;
    } else {
        WFTagCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        Tag *tag = searching ? _filteredTags[indexPath.item] : _tags[indexPath.item];
        [cell configureForTag:tag];
        if ([self.selectedTags containsObject:tag]){
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
    if ((searching && indexPath.row == _filteredTags.count) || (indexPath.row == _tags.count)){
        [self toggleEditMode];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        Tag *tag = searching ? _filteredTags[indexPath.item] : _tags[indexPath.item];
        [self.selectedTags addObject:tag];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    [self adjustTagButtonColor];
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
    
    [self.searchBar setPlaceholder:@"Search for relevant tags"];
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
        if (noResults){
            [searchBar resignFirstResponder];
        } else {
            [ProgressHUD show:@"Searching..."];
            [self loadTagsWithSearch:searchBar.text];
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (text.length) {
        [_filteredTags removeAllObjects];
        for (Tag *tag in _tags){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if ([predicate evaluateWithObject:tag.name]) {
                [_filteredTags addObject:tag];
            }
        }
        
        if (!_filteredTags.count) {
            [self loadTagsWithSearch:text];
        } else {
            noResults = NO;
        }
    } else {
        _filteredTags = [NSMutableOrderedSet orderedSetWithOrderedSet:_tags];
    }
    
    [self.collectionView reloadData];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItems = @[doneButton, spacerBarButton, noTagBarButton];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (tagNameTextField.text.length && [string isEqualToString:@"\n"]) {
        [self createTag];
        return NO;
    }
    return YES;
}

- (void)doneEditing {
    [self.view endEditing:YES];
    if (self.searchBar.isFirstResponder){
        [self.searchBar resignFirstResponder];
    }
    self.navigationItem.rightBarButtonItems = @[saveButton, spacerBarButton, noTagBarButton];
}

- (void)createTag {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.view endEditing:YES];
    });
    
    Tag *tag = [Tag MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    tag.name = tagNameTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (tag.name.length){
        [parameters setObject:tag.name forKey:@"name"];
    }
    
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",tag.name]];
    [manager POST:@"tags" parameters:@{@"tag":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a new tag: %@",responseObject);
        if ([responseObject objectForKey:@"tag"]){
            [tag populateFromDictionary:[responseObject objectForKey:@"tag"]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        //add the new tag to the selection
        [self.selectedTags addObject:tag];
        [ProgressHUD dismiss];
        
        if (self.tagDelegate && [self.tagDelegate respondsToSelector:@selector(tagsSelected:)]){
            [self.tagDelegate tagsSelected:self.selectedTags];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while. Please try again soon." withTime:2.7f];
        [ProgressHUD dismiss];
        NSLog(@"Failed to create a new tag: %@",error.description);
    }];
}

- (void)save {
    if (self.selectedTags.count){
        if (self.tagDelegate && [self.tagDelegate respondsToSelector:@selector(tagsSelected:)]){
            [self.tagDelegate tagsSelected:self.selectedTags];
        }
        [self dismiss];
        
    } else {
        if (self.tagDelegate && [self.tagDelegate respondsToSelector:@selector(tagsSelected:)]){
            [self.tagDelegate tagsSelected:nil];
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