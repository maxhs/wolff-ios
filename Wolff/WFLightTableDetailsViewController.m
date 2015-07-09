//
//  WFLightTableDetailsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableDetailsViewController.h"
#import "WFAppDelegate.h"
#import "WFLightTableDetailsCell.h"
#import "WFUtilities.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "WFAlert.h"
#import "WFLightTableKeyCell.h"
#import "WFLightTableContentsCell.h"
#import "WFUsersViewController.h"

@interface WFLightTableDetailsViewController () < UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITextViewDelegate, WFSelectUsersDelegate, WFLightTableDetailsDelegate> {
    BOOL iOS8;
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UIButton *joinButton;
    UITextField *joinTableTextField;
    UIBarButtonItem *cancelBarButton;
    UIBarButtonItem *dismissBarButton;
    UIBarButtonItem *rightBarButton;
    UIImageView *navBarShadowView;
    CGFloat topInset;
    CGFloat keyboardHeight;
    NSInteger currentPage;
    WFLightTableDetailsCell *detailsCell;
}
@property (strong, nonatomic) User *currentUser;
@end

@implementation WFLightTableDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.currentUser = [delegate.currentUser MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    
    if (self.lightTable){
        self.lightTable = [self.lightTable MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self loadLightTable];
    } else {
        self.lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [self.lightTable addOwner:self.currentUser];
        [self.lightTable addUser:self.currentUser];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    keyboardHeight = 0.f;
    topInset = self.navigationController.navigationBar.frame.size.height;
    
    if (IDIOM == IPAD){
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    } else {
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = dismissButton;
        //[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        //self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.view.backgroundColor = [UIColor clearColor];
        if ([self.lightTable.identifier isEqualToNumber:@0]){
            rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
        } else {
            rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction)];
        }
        
        self.navigationItem.rightBarButtonItem = rightBarButton;
        self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    }
    
    
    
    UIToolbar *backgroundView = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundView setTranslucent:YES];
    [backgroundView setBarStyle:UIBarStyleBlackTranslucent];
    [self.collectionView setBackgroundView:backgroundView];
    
    cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    dismissBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissBarButton;
    dismissBarButton.tintColor = [UIColor blackColor];
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    [_scrollBackButton addTarget:self action:@selector(scrollBack) forControlEvents:UIControlEventTouchUpInside];
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.lightTable.identifier isEqualToNumber:@0]){
        if (_joinMode){
            [joinTableTextField becomeFirstResponder];
        } else {
            [detailsCell startTypingTitle];
        }
    }
}

- (void)loadLightTable {
    [manager GET:[NSString stringWithFormat:@"light_tables/%@",self.lightTable.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading table from internet: %@",responseObject);
        [self.lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            //[self.collectionView reloadData];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get light table from API: %@",error.description);
    }];
}

#pragma mark - Collection view data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (IDIOM != IPAD && _joinMode){
        self.collectionView.scrollEnabled = NO;
        [self.navigationItem.rightBarButtonItem setTitle:@"Join"];
        return 1;
    } else {
        return 2;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_showKey){
        return 1;
    } else {
        if (section == 0){
            return 1;
        } else if (self.lightTable) {
            [_scrollBackButton setHidden:NO];
            return self.lightTable.photos.count;
        } else {
            [_scrollBackButton setHidden:YES];
            return 1;
        }
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        if (IDIOM != IPAD && _joinMode){
            WFLightTableKeyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableKeyCell" forIndexPath:indexPath];
            [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.03]];
            if (IDIOM == IPAD){
                [cell.label setText:@"TABLE KEY - THE PASSWORD REQUIRED TO JOIN THIS LIGHT TABLE"];
                [cell.textField setPlaceholder:@"The key code for the light table code you'd like to join"];
            } else {
                [cell.label setText:@"TABLE KEY - THE PASSWORD TO JOIN"];
                [cell.textField setPlaceholder:@"The key code for this light table"];
            }
            
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            cell.textField.delegate = self;
            [cell.joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
            [cell.joinButton addTarget:self action:@selector(joinLightTable) forControlEvents:UIControlEventTouchUpInside];
            joinButton = cell.joinButton;
            joinTableTextField = cell.textField;
            return cell;
        } else {
            detailsCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableDetailsCell" forIndexPath:indexPath];
            [detailsCell setBackgroundColor:[UIColor clearColor]];
            detailsCell.lightTableDelegate = self;
            [detailsCell configureWithLightTable:self.lightTable];
            return detailsCell;
        }
    } else {
        if (_showKey){
            WFLightTableKeyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableKeyCell" forIndexPath:indexPath];
            [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.03]];
            if (IDIOM == IPAD){
                [cell.label setText:@"TABLE KEY - THE PASSWORD REQUIRED TO JOIN THIS LIGHT TABLE"];
                [cell.textField setPlaceholder:@"The key code for the light table code you'd like to join"];
            } else {
                [cell.label setText:@"TABLE KEY - THE PASSWORD TO JOIN"];
                [cell.textField setPlaceholder:@"The key code for this light table"];
            }
            
            [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            cell.textField.delegate = self;
            [cell.joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
            [cell.joinButton addTarget:self action:@selector(joinLightTable) forControlEvents:UIControlEventTouchUpInside];
            joinButton = cell.joinButton;
            joinTableTextField = cell.textField;
            return cell;
        } else {
            WFLightTableContentsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableContentsCell" forIndexPath:indexPath];
            Photo *photo = self.lightTable.photos[indexPath.item];
            [cell configureForPhoto:photo];
            return cell;
        }
    }
}

- (void)rightBarButtonAction {
    if (currentPage == 1 || _joinMode){
        [self joinLightTable];
    } else {
        [detailsCell post];
    }
}

- (void)didCreateLightTable:(LightTable *)table {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [WFAlert show:[NSString stringWithFormat:@"\"%@\" successfully created",_lightTable.name] withTime:2.7f];
    }];
}

- (void)didUpdateLightTable:(LightTable *)table {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [ProgressHUD dismiss];
        [WFAlert show:[NSString stringWithFormat:@"\"%@\" successfully saved",_lightTable.name] withTime:2.7f];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)keyboardUp {
    self.navigationItem.rightBarButtonItem = cancelBarButton;
}

- (void)keyboardDown {
    self.navigationItem.rightBarButtonItem = rightBarButton;
}

- (void)showOwners {
    [detailsCell save];
    WFUsersViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Users"];
    [vc setSelectedUsers:self.lightTable.owners.mutableCopy];
    [vc setOwnerMode:YES];
    vc.userDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];

    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showMembers {
    [detailsCell save];
    WFUsersViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Users"];
    [vc setSelectedUsers:self.lightTable.users.mutableCopy];
    vc.userDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self presentViewController:nav animated:YES completion:^{
    
    }];
}

- (void)lightTableOwnersSelected:(NSOrderedSet *)selectedOwners {
    self.lightTable = [self.lightTable MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    self.lightTable.owners = selectedOwners;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.collectionView reloadData];
    }];
}

- (void)usersSelected:(NSOrderedSet *)selectedUsers {
    self.lightTable = [self.lightTable MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    self.lightTable.users = selectedUsers;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.collectionView reloadData];
    }];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(width/2,height);
    } else {
        return CGSizeMake(width,height);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x >= width && _scrollBackButton.alpha == 0.f){
        [self animateScrollButton];
    } else if (_scrollBackButton.alpha == 1.f && scrollView.contentOffset.x < width){
        [self animateScrollButton];
    }
    
    if (IDIOM != IPAD){
        CGFloat pageHeight = scrollView.frame.size.height;
        CGFloat offsetX = scrollView.contentOffset.y;
        float fractionalPage = offsetX / pageHeight;
        NSInteger page = lround(fractionalPage);
        if (currentPage != page) {
            currentPage = page;
            NSLog(@"current page: %lu",(unsigned long)currentPage);
            if (currentPage == 0){
                if (![self.lightTable.identifier isEqualToNumber:@0]){
                    self.title = @"Edit";
                    [rightBarButton setTitle:@"Save"];
                } else {
                    self.title = @"Create a Light Table";
                    [rightBarButton setTitle:@"Create"];
                }
            } else if (currentPage == 1){
                self.title = @"Join";
                [rightBarButton setTitle:@"Join"];
            }
        }
    }
}

- (void)animateScrollButton {
    if (_scrollBackButton.alpha == 0.f){
        [UIView animateWithDuration:.23 animations:^{
           [_scrollBackButton setAlpha:1.f];
        }];
    } else {
        [UIView animateWithDuration:.23 animations:^{
            [_scrollBackButton setAlpha:0.f];
        }];
    }
}

- (void)scrollBack {
    [_collectionView setContentOffset:CGPointZero animated:YES];
}

- (void)joinLightTable {
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (joinTableTextField.text.length){
        [parameters setObject:joinTableTextField.text forKey:@"code"];
    } else {
        [WFAlert show:@"Please make sure you've entered a valid key before attempting to join a light table" withTime:3.3f];
        return;
    }
    
    [ProgressHUD show:@"Searching for light table..."];
    [manager POST:@"light_tables/join" parameters:@{@"light_table":parameters, @"user_id":self.currentUser.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Response object for joining a light table: %@",responseObject);
        NSDictionary *lightTableDict = [responseObject objectForKey:@"light_table"];
        if (_lightTable.identifier && [_lightTable.identifier isEqualToNumber:[lightTableDict objectForKey:@"id"]]){
            [_lightTable populateFromDictionary:lightTableDict];
        } else {
            _lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [_lightTable populateFromDictionary:lightTableDict];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didJoinLightTable:)]){
                [self.lightTableDelegate didJoinLightTable:_lightTable];
            }
            [ProgressHUD dismiss];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [WFAlert show:[NSString stringWithFormat:@"You just joined \"%@\"",_lightTable.name] withTime:3.3f];
            }];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"operation response: %@",operation.responseString);
        if ([operation.responseString isEqualToString:kIncorrectLightTableCode]){
            [WFAlert show:@"We couldn't find a light table for that key."  withTime:3.3f];
        } else if ([operation.responseString isEqualToString:kNoLightTable]){
            [WFAlert show:@"We couldn't find a light table for that key."  withTime:3.3f];
        } else {
            NSLog(@"Error joining light table: %@",error.description);
        }
        [ProgressHUD dismiss];
    }];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!textView.text.length){
        [textView setText:kLightTableDescriptionPlaceholder];
        [textView setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
        //[textView setTextColor:kPlaceholderTextColor];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {

}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == joinTableTextField){
        NSString *newText = [joinTableTextField.text stringByReplacingCharactersInRange:range withString:string];
        if (newText.length){
            [joinButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
            joinButton.enabled = YES;
        } else {
            [joinButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
            joinButton.enabled = NO;
        }
    }
    return YES;
}

- (void)doneEditing {
    [self.view endEditing:YES];
    [detailsCell doneEditing];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
//    NSDictionary* info = [note userInfo];
//    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
//    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
//    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
//    keyboardHeight = convertedKeyboardFrame.size.height;
//    [UIView animateWithDuration:duration
//                          delay:0
//                        options:curve | UIViewAnimationOptionBeginFromCurrentState
//                     animations:^{
//                         //self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
//                         //self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
//                     } completion:^(BOOL finished) {
//                     
//                     }];
}

- (void)keyboardWillHide:(NSNotification *)note {
//    NSDictionary* info = [note userInfo];
//    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
//    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
//    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
//    keyboardHeight = convertedKeyboardFrame.size.height;
//
//    [UIView animateWithDuration:duration
//                          delay:0
//                        options:curve | UIViewAnimationOptionBeginFromCurrentState
//                     animations:^{
//                         //self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
//                         //self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
//                     } completion:nil];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (delegate.connected && [self.lightTable.identifier isEqualToNumber:@0]){
            [self.lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self doneEditing];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
