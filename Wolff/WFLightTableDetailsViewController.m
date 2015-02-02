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

#define kLightTableDescriptionPlaceholder @"Describe your light table..."

@interface WFLightTableDetailsViewController () < UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITextViewDelegate> {
    BOOL iOS8;
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UITextField *joinTableTextField;
    UITextField *titleTextField;
    UITextField *tableKeyTextField;
    UITextField *confirmTableKeyTextField;
    UIButton *joinButton;
    UIButton *actionButton;
    UITextView *descriptionTextView;
    UIBarButtonItem *dismissBarButton;
    UIImageView *navBarShadowView;
    Table *_lightTable;
    CGFloat topInset;
    CGFloat keyboardHeight;
}

@end

@implementation WFLightTableDetailsViewController
@synthesize photos = _photos;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    keyboardHeight = 0.f;
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    UIToolbar *backgroundView = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundView setTranslucent:YES];
    [backgroundView setBarStyle:UIBarStyleDefault];
    [self.collectionView setBackgroundView:backgroundView];
    
    dismissBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackRemove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissBarButton;
    dismissBarButton.tintColor = [UIColor blackColor];
    [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    self.title = @"New Light Table";
    
    if (!_tableId || [_tableId isEqualToNumber:@0]){
        _lightTable = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    } else {
        _lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:_tableId inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    if (!_lightTable){
        [manager GET:[NSString stringWithFormat:@"light_tables/%@",_tableId] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading table from internet: %@",responseObject);
            [_lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
            [_collectionView reloadData];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get light table from API: %@",error.description);
        }];
    }

    [_scrollBackButton addTarget:self action:@selector(scrollBack) forControlEvents:UIControlEventTouchUpInside];
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [titleTextField becomeFirstResponder];
}

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_showKey){
        return 1;
    } else {
        if (section == 0){
            return 1;
        } else if (_lightTable) {
            [_scrollBackButton setHidden:NO];
            return _lightTable.photos.count;
        } else {
            [_scrollBackButton setHidden:YES];
            return 1;
        }
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        WFLightTableDetailsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableDetailsCell" forIndexPath:indexPath];
        [cell setBackgroundColor:[UIColor clearColor]];
        
        if (_lightTable){
            [cell.actionButton setTitle:@"SAVE" forState:UIControlStateNormal];
        } else {
            [cell.actionButton setTitle:@"CREATE" forState:UIControlStateNormal];
        }
        
        [cell.actionButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
        [cell.actionButton setUserInteractionEnabled:YES];
        cell.titleTextField.delegate = self;
        cell.keyTextField.delegate = self;
        cell.confirmKeyTextField.delegate = self;
        
        titleTextField = cell.titleTextField;
        [cell.titleTextField setPlaceholder:@"e.g. Mesopotamian Pots"];
        [cell.titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [cell.titleTextField setReturnKeyType:UIReturnKeyNext];

        if (_lightTable) {
            [cell.titleTextField setText:_lightTable.name];
            [cell.keyTextField setText:_lightTable.code];
            [cell.confirmKeyTextField setText:_lightTable.code];
        }
        
        cell.textView.delegate = self;
        [cell.textView setHidden:NO];
        descriptionTextView = cell.textView;
        if (_lightTable && _lightTable.tableDescription.length){
            [cell.textView setText:_lightTable.tableDescription];
            [cell.textView setTextColor:[UIColor blackColor]];
        } else {
            [cell.textView setText:kLightTableDescriptionPlaceholder];
            [cell.textView setTextColor:kPlaceholderTextColor];
        }
        cell.textView.delegate = self;
        [cell.textView setReturnKeyType:UIReturnKeyDefault];

        tableKeyTextField = cell.keyTextField;
        [cell.keyTextField setPlaceholder:@"Your light table key"];
        [cell.keyTextField setReturnKeyType:UIReturnKeyNext];

        confirmTableKeyTextField = cell.confirmKeyTextField;
        [cell.confirmKeyTextField setPlaceholder:@"Confirm table key"];
        [cell.confirmKeyTextField setReturnKeyType:UIReturnKeyGo];
        
        actionButton = cell.actionButton;
        return cell;
    } else {
        if (_showKey){
            WFLightTableKeyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableKeyCell" forIndexPath:indexPath];
            [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.03]];
            [cell.label setText:@"TABLE KEY"];
            [cell.textField setPlaceholder:@"The key code for the light table code you'd like to join"];
            cell.textField.delegate = self;
            [cell.joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
            [cell.joinButton addTarget:self action:@selector(joinLightTable) forControlEvents:UIControlEventTouchUpInside];
            joinButton = cell.joinButton;
            joinTableTextField = cell.textField;
            return cell;
        } else {
            WFLightTableContentsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableContentsCell" forIndexPath:indexPath];
            Photo *photo = _lightTable.photos[indexPath.item];
            [cell configureForPhoto:photo];
            return cell;
        }
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(width/2,height);
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

- (void)post {
    if (_lightTable){
        [self saveLightTable];
    } else {
        [self createLightTable];
    }
}

- (NSMutableDictionary*)generateParameters {
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return nil;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return nil;
    }
    
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"name"];
    } else {
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return nil;
    }
    if (descriptionTextView.text.length){
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"owner_id"];
    }
    
    NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:_photos.count];
    for (Photo *photo in _photos){
        [photoIds addObject:photo.identifier];
    }
    [parameters setObject:photoIds forKey:@"photo_ids"];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_ids"];
    return parameters;
}

- (void)createLightTable {
    NSMutableDictionary *parameters = [self generateParameters];
    if (parameters == nil){
        return;
    }
    [ProgressHUD show:[NSString stringWithFormat:@"Creating \"%@\"",titleTextField.text]];
    [manager POST:@"light_tables" parameters:@{@"light_table":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success creating a light table: %@", responseObject);
        [_lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" successfully created",_lightTable.name] withTime:2.7f];
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didCreateLightTable:)]){
                [self.lightTableDelegate didCreateLightTable:_lightTable];
            }
            [self dismiss];
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"Sorry, but there's already another light table using that key code.\n\nPlease choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error creating a light table: %@",error.description);
        }
    }];
}

- (void)saveLightTable {
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (titleTextField.text.length){
        [parameters setObject:titleTextField.text forKey:@"name"];
    } else {
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    if (descriptionTextView.text.length){
        [parameters setObject:descriptionTextView.text forKey:@"description"];
    }
    if (tableKeyTextField.text.length && [tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
        [parameters setObject:tableKeyTextField.text forKey:@"code"];
    }
    
    [ProgressHUD show:@"Saving light table..."];
    [manager PATCH:[NSString stringWithFormat:@"light_tables/%@",_lightTable.identifier] parameters:@{@"light_table":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success saving a light table: %@", responseObject);
        [_lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" successfully saved",_lightTable.name] withTime:2.7f];
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didSaveLightTable:)]){
                [self.lightTableDelegate didSaveLightTable:_lightTable];
            }
            [self dismiss];
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"Sorry, but there's already another light table using that key code.\n\nPlease choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error saving a light table: %@",error.description);
        }
    }];
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
    if (_lightTable && ![_lightTable.identifier isEqualToNumber:@0]) {
        [parameters setObject:_lightTable.identifier forKey:@"id"];
    }
    
    [ProgressHUD show:@"Searching for light table..."];
    [manager POST:@"light_tables/join" parameters:@{@"light_table":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response object for joining a light table: %@",responseObject);
        NSDictionary *lightTableDict = [responseObject objectForKey:@"light_table"];
        if (_lightTable.identifier && [_lightTable.identifier isEqualToNumber:[lightTableDict objectForKey:@"id"]]){
            [_lightTable populateFromDictionary:lightTableDict];
        } else {
            _lightTable = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            [_lightTable populateFromDictionary:lightTableDict];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [WFAlert show:[NSString stringWithFormat:@"You just joined \"%@\"",_lightTable.name] withTime:3.3f];
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didJoinLightTable:)]){
                [self.lightTableDelegate didJoinLightTable:_lightTable];
            }
            [ProgressHUD dismiss];
            [self dismiss];
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
        [textView setTextColor:kPlaceholderTextColor];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        if (textField == titleTextField){
            [descriptionTextView becomeFirstResponder];
        } else if (textField == tableKeyTextField) {
            [confirmTableKeyTextField becomeFirstResponder];
        } else if (textField == confirmTableKeyTextField) {
            [self createLightTable];
        }
        return NO;
    } else {
        
        if (textField == joinTableTextField){
            NSString *newText = [joinTableTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (newText.length){
                [joinButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                joinButton.enabled = YES;
            } else {
                [joinButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                joinButton.enabled = NO;
            }
        } else if (textField == confirmTableKeyTextField){
            NSString *newText = [confirmTableKeyTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (titleTextField.text.length && [tableKeyTextField.text isEqualToString:newText]){
                [actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                actionButton.enabled = YES;
            } else {
                [actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                actionButton.enabled = NO;
            }
        } else if (textField == tableKeyTextField){
            NSString *newText = [tableKeyTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (titleTextField.text.length && [confirmTableKeyTextField.text isEqualToString:newText]){
                [actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                actionButton.enabled = YES;
            } else {
                [actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                actionButton.enabled = NO;
            }
        } else if (textField == titleTextField){
            NSString *newText = [titleTextField.text stringByReplacingCharactersInRange:range withString:string];
            if (newText.length && ((tableKeyTextField.text.length && [confirmTableKeyTextField.text isEqualToString:tableKeyTextField.text]) || _lightTable)){
                [actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
                actionButton.enabled = YES;
            } else {
                [actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
                actionButton.enabled = NO;
            }
        }
        return YES;
    }
}

- (void)doneEditing {
    [self.view endEditing:YES];
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
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         //self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         //self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     } completion:^(BOOL finished) {
                     
                     }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;

    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         //self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         //self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     } completion:nil];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
