//
//  WFMaterialsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFMaterialsViewController.h"
#import "Constants.h"
#import "WFAppDelegate.h"
#import "WFAlert.h"
#import "WFUtilities.h"
#import "WFNewMaterialCell.h"
#import "WFMaterialCollectionCell.h"

@interface WFMaterialsViewController () <WFSelectMaterialsDelegate, UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    BOOL searching;
    BOOL editing;
    CGFloat width;
    CGFloat height;
    CGFloat topInset;
    NSString *searchText;
    NSMutableOrderedSet *_materials;
    NSMutableOrderedSet *_filteredMaterials;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *doneButton;
    UITextField *materialTextField;
    UIButton *noMaterialsButton;
    UIBarButtonItem *unknownBarButton;
    UIBarButtonItem *spacerBarButton;
    UIImageView *navBarShadowView;
}
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;
@end

@implementation WFMaterialsViewController
@synthesize selectedMaterials = _selectedMaterials;

static NSString * const reuseIdentifier = @"MaterialCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    width = screenWidth(); height = screenHeight();
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    _materials = [NSMutableOrderedSet orderedSetWithArray:[Material MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
    _filteredMaterials = [NSMutableOrderedSet orderedSet];
    dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    
    noMaterialsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [noMaterialsButton.titleLabel setFont:[UIFont fontWithName:kMuseoSans size:12]];
    [noMaterialsButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [noMaterialsButton addTarget:self action:@selector(materialUnknownToggled) forControlEvents:UIControlEventTouchUpInside];
    [noMaterialsButton setFrame:CGRectMake(0, 0, 170.f, 44.f)];
    [noMaterialsButton setTitle:@"NO MATERIALS" forState:UIControlStateNormal];
    unknownBarButton = [[UIBarButtonItem alloc] initWithCustomView:noMaterialsButton];
    spacerBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerBarButton.width = 23.f;
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

- (void)materialUnknownToggled {
    [_selectedMaterials removeAllObjects];
    [self adjustUnknownButtonColor];
    [_collectionView reloadData];
}

- (void)adjustUnknownButtonColor {
    if (_selectedMaterials.count){
        [noMaterialsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [noMaterialsButton setTitleColor:kSaffronColor forState:UIControlStateNormal];
    }
}

- (void)loadMaterialsWithSearch:(NSString*)searchString {
    if (self.mainRequest) return;
    if (searchString.length){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        }
        if (searchString.length){
            [parameters setObject:searchString forKey:@"search"];
        }
        [manager POST:@"materials/search" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading materials: %@",responseObject);
            for (id dict in [responseObject objectForKey:@"materials"]){
                Material *material = [Material MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext    :[NSManagedObjectContext MR_defaultContext]];
                if (!material){
                    material = [Material MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [material populateFromDictionary:dict];
                [_filteredMaterials addObject:material];
                [_materials addObject:material];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                _materials = [NSMutableOrderedSet orderedSetWithArray:[Material MR_findAllSortedBy:@"name" ascending:YES inContext:[NSManagedObjectContext MR_defaultContext]]];
                [_collectionView reloadData];
                self.mainRequest = nil;
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WFAlert show:@"Sorry, something went wrong while trying to fetch material info.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            self.mainRequest = nil;
            NSLog(@"Failed to load materials: %@",error.description);
        }];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (searching){
        return _filteredMaterials.count + 1;
    } else {
        return _materials.count + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((searching && indexPath.row == _filteredMaterials.count) || (indexPath.row == _materials.count)){
        WFNewMaterialCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NewMaterialCell" forIndexPath:indexPath];
        if (editing){
            [cell.prompt setHidden:YES];
            [cell.label setHidden:NO];
            [cell.materialNameTextField setHidden:NO];
            [cell.materialNameTextField setPlaceholder:@"+  add a new material"];

            if (searchText.length){
                [cell.materialNameTextField setText:searchText];
            } else {
                [cell.materialNameTextField setText:@""];
            }
            [cell.createButton setHidden:NO];
            [cell.createButton addTarget:self action:@selector(createMaterial) forControlEvents:UIControlEventTouchUpInside];
            [cell.materialNameTextField becomeFirstResponder];
            [cell.materialNameTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
            [cell.materialNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
            [cell.materialNameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [cell.materialNameTextField setReturnKeyType:UIReturnKeyDone];
            cell.materialNameTextField.delegate = self;
            materialTextField = cell.materialNameTextField;
            [materialTextField becomeFirstResponder];
        } else {
            [cell.prompt setHidden:NO];
            [cell.materialNameTextField setHidden:YES];
            [cell.label setHidden:YES];
            if (searchText.length){
                [cell.prompt setText:[NSString stringWithFormat:@"+  add \"%@\"",searchText]];
            } else {
                [cell.prompt setText:@"+  add a new material"];
            }
            [cell.createButton setHidden:YES];
        }
        return cell;
    } else {
        WFMaterialCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        Material * material = searching ? _filteredMaterials[indexPath.item] : _materials[indexPath.item];
        [cell configureForMaterial:material];
        if ([_selectedMaterials containsObject:material]){
            [cell.checkmark setHidden:NO];
        } else {
            [cell.checkmark setHidden:YES];
        }
        return cell;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == materialTextField && [string isEqualToString:@"\n"]) {
        [self createMaterial];
    }
    return YES;
}

- (void)materialsSelected:(NSOrderedSet *)selectedMaterials {
    
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
    if ((searching && indexPath.row == _filteredMaterials.count) || (indexPath.row == _materials.count)){
        [self toggleEditMode];
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        Material *material = searching ? _filteredMaterials[indexPath.item] : _materials[indexPath.item];
        if ([_selectedMaterials containsObject:material]){
            [_selectedMaterials removeObject:material];
        } else {
            [_selectedMaterials addObject:material];
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
    
    [self.searchBar setPlaceholder:@"Search for material(s)"];
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
        [self loadMaterialsWithSearch:searchBar.text];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    if (text.length) {
        [_filteredMaterials removeAllObjects];
        for (Material *material in _materials){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if ([predicate evaluateWithObject:material.name]) {
                [_filteredMaterials addObject:material];
            }
        }
        if (_filteredMaterials.count == 0) {
            [self loadMaterialsWithSearch:text];
        }
    } else {
        _filteredMaterials = [NSMutableOrderedSet orderedSetWithOrderedSet:_materials];
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

- (void)createMaterial {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.view endEditing:YES];
    });
    
    Material *material = [Material MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    material.name = materialTextField.text;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:material.name forKey:@"name"];
    [ProgressHUD show:[NSString stringWithFormat:@"Adding \"%@\"",material.name]];
    [manager POST:@"materials" parameters:@{@"material":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a new material: %@",responseObject);
        if ([responseObject objectForKey:@"material"]){
            [material populateFromDictionary:[responseObject objectForKey:@"material"]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        //add the new material to the selection
        [_selectedMaterials addObject:material];
        [ProgressHUD dismiss];
        
        if (self.materialDelegate && [self.materialDelegate respondsToSelector:@selector(materialsSelected:)]){
            [self.materialDelegate materialsSelected:_selectedMaterials];
        }
        [self dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WFAlert show:@"Sorry, but something went wrong while. Please try again soon." withTime:2.7f];
        [ProgressHUD dismiss];
        NSLog(@"Failed to create a new material: %@",error.description);
    }];
}

- (void)save {
    if (_selectedMaterials.count){
        
        if (self.materialDelegate && [self.materialDelegate respondsToSelector:@selector(materialsSelected:)]){
            [self.materialDelegate materialsSelected:_selectedMaterials];
        }
        [self dismiss];

    } else {
        if (self.materialDelegate && [self.materialDelegate respondsToSelector:@selector(materialsSelected:)]){
            [self.materialDelegate materialsSelected:nil];
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
