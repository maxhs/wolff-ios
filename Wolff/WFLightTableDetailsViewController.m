//
//  WFLightTableDetailsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableDetailsViewController.h"
#import "WFAppDelegate.h"
#import "WFUtilities.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "WFAlert.h"
#import "WFLightTableContentsCell.h"
#import "WFUsersViewController.h"
#import "WFLightTableDetailsCell.h"
#import "NSArray+ToSentence.h"

@interface WFLightTableDetailsViewController () < UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UITextViewDelegate, WFSelectUsersDelegate, UITableViewDataSource, UITableViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UIBarButtonItem *cancelBarButton;
    UIBarButtonItem *dismissBarButton;
    UIBarButtonItem *rightBarButton;
    UIImageView *navBarShadowView;
    CGFloat topInset;
    CGFloat keyboardHeight;
    NSInteger currentPage;
    
    UITextField *nameTextField;
    UITextField *tableKeyTextField;
    UITextField *confirmTableKeyTextField;
    UITextField *ownersTextField;
    UITextField *membersTextField;
    UITextView *descriptionTextView;
}
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;
@property (strong, nonatomic) AFHTTPRequestOperation *postRequest;
@property (strong, nonatomic) NSMutableOrderedSet *owners;
@property (strong, nonatomic) NSMutableOrderedSet *users;
@property (strong, nonatomic) User *currentUser;
@end

@implementation WFLightTableDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    
    width = screenWidth();
    height = screenHeight();
    
    if (self.lightTable){
        self.lightTable = [self.lightTable MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        self.owners = self.lightTable.owners.mutableCopy;
        self.users = self.lightTable.users.mutableCopy;
        [self loadLightTable];
        [self.collectionView setHidden:NO];
    } else if (self.currentUser) {
        CGRect tableViewRect = self.tableView.frame;
        tableViewRect.origin.x = width/2 - (tableViewRect.size.width/2);
        [self.tableView setFrame:tableViewRect];
        self.owners = [NSMutableOrderedSet orderedSetWithObject:self.currentUser];
        self.users = [NSMutableOrderedSet orderedSetWithObject:self.currentUser];
        [self.collectionView setHidden:YES];
    }
    
    if (_lightTable){
        [_actionButton setTitle:@"SAVE" forState:UIControlStateNormal];
    } else if (_joinMode){
        [_actionButton setTitle:@"JOIN" forState:UIControlStateNormal];
        [self.switchModesButton setTitle:@"Create a light table instead" forState:UIControlStateNormal];
    } else {
        [_actionButton setTitle:@"CREATE" forState:UIControlStateNormal];
        [self.switchModesButton setTitle:@"Join a light table instead" forState:UIControlStateNormal];
    }
    [_actionButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
    
    [self.switchModesButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [self.switchModesButton addTarget:self action:@selector(switchModes) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self setupTableViewHeader];
    
    keyboardHeight = 0.f;
    topInset = self.navigationController.navigationBar.frame.size.height;
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    if (IDIOM == IPAD){
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    } else {
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.view.backgroundColor = [UIColor clearColor];
        if (_joinMode){
            rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Join" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        } else if (![_lightTable.identifier isEqualToNumber:@0]){
            rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        } else {
            rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(post)];
        }
        
        self.navigationItem.rightBarButtonItem = rightBarButton;
        self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    }
    
    UIToolbar *backgroundView = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundView setTranslucent:YES];
    [backgroundView setBarStyle:UIBarStyleBlackTranslucent];
    [self.view insertSubview:backgroundView belowSubview:self.tableView];
    [self.view sendSubviewToBack:backgroundView];
    
    cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneEditing)];
    dismissBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
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
    if (_joinMode && !tableKeyTextField.text.length){
        [tableKeyTextField becomeFirstResponder];
    } else if (!nameTextField.text.length) {
        [nameTextField becomeFirstResponder];
    }
}

- (void)switchModes {
    _joinMode = !_joinMode;
    [self.tableView reloadData];
    if (_joinMode){
        [_switchModesButton setTitle:@"Create a light table instead" forState:UIControlStateNormal];
        [_actionButton setTitle:@"JOIN" forState:UIControlStateNormal];
    } else {
        [_switchModesButton setTitle:@"Join a light table instead" forState:UIControlStateNormal];
        [_actionButton setTitle:@"CREATE" forState:UIControlStateNormal];
    }
    [self checkFormStatus];
}

- (void)setupTableViewHeader {
    self.tableView.tableHeaderView = self.topContainerView;
    [self.topContainerView setBackgroundColor:[UIColor clearColor]];
    [_headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.9]];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _actionButton.layer.cornerRadius = 14.f;
    _actionButton.clipsToBounds = YES;
    [_actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setShowsVerticalScrollIndicator:NO];
}

- (void)configureWithLightTable:(LightTable*)lightTable{
    self.lightTable = [lightTable MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    
    self.tableView.tableHeaderView = _topContainerView;
    [self.tableView reloadData];
    if (IDIOM == IPAD){
        if ([self.lightTable.identifier isEqualToNumber:@0]){
            [self.actionButton setTitle:@"CREATE" forState:UIControlStateNormal];
            [self.headerLabel setText:@"CREATE A LIGHT TABLE"];
        } else {
            [self.actionButton setTitle:@"SAVE" forState:UIControlStateNormal];
            if (self.lightTable.name.length){
                [self.headerLabel setText:self.lightTable.name];
            } else {
                [self.headerLabel setText:@"EDIT YOUR LIGHT TABLE"];
            }
        }
        [self.actionButton addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton setUserInteractionEnabled:YES];
    } else {
        [self.actionButton setHidden:YES];
        [self.headerLabel setText:@""];
    }
}

- (void)loadLightTable {
    if (self.mainRequest) return;
    
    [ProgressHUD show:[NSString stringWithFormat:@"Fetching details for \"%@\"",self.lightTable.name]];
    self.mainRequest = [manager GET:[NSString stringWithFormat:@"light_tables/%@",self.lightTable.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading table from internet: %@",responseObject);
        [self.lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            self.owners = self.lightTable.owners.mutableCopy;
            self.users = self.lightTable.users.mutableCopy;
            [self.tableView reloadData];
            self.mainRequest = nil;
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get light table from API: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

#pragma mark - Collection view data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.lightTable) {
        [_scrollBackButton setHidden:NO];
        return self.lightTable.photos.count;
    } else {
        [_scrollBackButton setHidden:YES];
        return 1;
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFLightTableContentsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightTableContentsCell" forIndexPath:indexPath];
    Photo *photo = self.lightTable.photos[indexPath.item];
    [cell configureForPhoto:photo];
    return cell;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _joinMode ? 1 : 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFLightTableDetailsCell *cell = (WFLightTableDetailsCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableCell"];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textView setHidden:YES];
    [cell.textField setHidden:NO];
    cell.textField.delegate = self;
    
    [cell.textField setUserInteractionEnabled:YES];
    
    switch (indexPath.row) {
        case 0:
            if (_joinMode){
                tableKeyTextField = cell.textField;
                [tableKeyTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                [tableKeyTextField setText:self.lightTable.code];
                [tableKeyTextField setPlaceholder:@"Your light table key"];
                [tableKeyTextField setReturnKeyType:UIReturnKeyNext];
                if (IDIOM == IPAD){
                    [cell.cellLabel setText:@"TABLE KEY - THE PASSWORD REQUIRED TO JOIN THIS LIGHT TABLE"];
                } else {
                    [cell.cellLabel setText:@"TABLE KEY - YOUR PASSWORD FOR THIS LIGHT TABLE"];
                }
            } else {
                nameTextField = cell.textField;
                [nameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                [nameTextField setPlaceholder:@"e.g. Mesopotamian Pots"];
                if (self.lightTable){
                    [cell.textField setText:self.lightTable.name];
                }
                [cell.cellLabel setText:@"NAME"];
                [nameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                [nameTextField setReturnKeyType:UIReturnKeyNext];
            }
            break;
        case 1:
            descriptionTextView = cell.textView;
            descriptionTextView.delegate = self;
            [cell.cellLabel setText:@"DESCRIPTION"];
            [cell.textField setHidden:YES];
            
            if (self.lightTable.tableDescription.length){
                [descriptionTextView setText:self.lightTable.tableDescription];
                [descriptionTextView setTextColor:[UIColor whiteColor]];
            } else if (!descriptionTextView.text.length || [descriptionTextView.text isEqualToString:kLightTableDescriptionPlaceholder]) {
                [descriptionTextView setText:kLightTableDescriptionPlaceholder];
                [descriptionTextView setTextColor:kLightTablePlaceholderTextColor];
            } else {
                [descriptionTextView setTextColor:[UIColor whiteColor]];
            }
            
            [descriptionTextView setReturnKeyType:UIReturnKeyDefault];
            [cell.textView setHidden:NO];
            break;
        case 2:
            tableKeyTextField = cell.textField;
            [tableKeyTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            if (self.lightTable){
                [tableKeyTextField setText:self.lightTable.code];
                [tableKeyTextField setBackgroundColor:[UIColor clearColor]];
                [tableKeyTextField setTextColor:[UIColor whiteColor]];
                [tableKeyTextField setUserInteractionEnabled:NO];
            } else {
                [tableKeyTextField setUserInteractionEnabled:YES];
            }
            [tableKeyTextField setPlaceholder:@"Your light table key"];
            [tableKeyTextField setReturnKeyType:UIReturnKeyNext];
            if (IDIOM == IPAD){
                [cell.cellLabel setText:@"TABLE KEY - THE PASSWORD REQUIRED TO JOIN THIS LIGHT TABLE"];
            } else {
                [cell.cellLabel setText:@"TABLE KEY - YOUR PASSWORD FOR THIS LIGHT TABLE"];
            }
            break;
        case 3:
            [cell.cellLabel setText:@"CONFIRM TABLE KEY"];
            confirmTableKeyTextField = cell.textField;
            [confirmTableKeyTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            if (self.lightTable){
                [confirmTableKeyTextField setText:self.lightTable.code];
                [confirmTableKeyTextField setBackgroundColor:[UIColor clearColor]];
                [confirmTableKeyTextField setTextColor:[UIColor whiteColor]];
                [confirmTableKeyTextField setUserInteractionEnabled:NO];
            } else {
                [confirmTableKeyTextField setUserInteractionEnabled:YES];
            }
            [confirmTableKeyTextField setPlaceholder:@"Confirm that your table key matches"];
            [confirmTableKeyTextField setReturnKeyType:UIReturnKeyGo];
            
            break;
        case 4:
            [cell.cellLabel setText:@"OWNERS"];
            ownersTextField = cell.textField;
            [ownersTextField setPlaceholder:@"Select who can manage this light table"];
            [ownersTextField setUserInteractionEnabled:NO];
            if (self.owners.count){
                [cell.textField setText:[self peopleToSentence:self.owners]];
            } else {
                [cell.textField setText:@""];
            }
            break;
        case 5:
            membersTextField = cell.textField;
            [membersTextField setPlaceholder:@"Add or remove light table members"];
            [membersTextField setUserInteractionEnabled:NO];
            if (self.users.count){
                [cell.textField setText:[self peopleToSentence:self.users]];
            } else {
                [cell.textField setText:@""];
            }
            [cell.cellLabel setText:@"MEMBERS"];
            break;
            
        default:
            break;
    }
    return cell;
}

- (NSString *)peopleToSentence:(NSMutableOrderedSet*)people {
    NSMutableArray *peoples = [NSMutableArray arrayWithCapacity:people.count];
    [people enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        if (user.fullName.length){
            [peoples addObject:user.fullName];
        }
    }];
    return [peoples toSentence];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1){
        return 130.f;
    } else {
        return 80.f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 4){
        [self showOwners];
    } else if (indexPath.row == 5){
        [self showMembers];
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

- (void)post {
    [self doneEditing];
    if (_lightTable){
        [self saveLightTable];
    } else if (_joinMode){
        [self joinLightTable];
    } else {
        [self createLightTable];
    }
}

- (NSMutableDictionary*)generateParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    NSMutableArray *ownerIds = [NSMutableArray arrayWithCapacity:self.owners.count];
    [self.owners enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        [ownerIds addObject:user.identifier];
    }];
    [parameters setObject:ownerIds forKey:@"owner_ids"];
    
    NSMutableArray *userIds = [NSMutableArray arrayWithCapacity:self.owners.count];
    [self.users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
        [userIds addObject:user.identifier];
    }];
    [parameters setObject:userIds forKey:@"user_ids"];
    
    NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:self.photos.count];
    [self.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        [photoIds addObject:photo.identifier];
    }];
    [parameters setObject:photoIds forKey:@"photo_ids"];
    
    [parameters setObject:descriptionTextView.text forKey:@"description"];
    [parameters setObject:nameTextField.text forKey:@"name"];
    [parameters setObject:tableKeyTextField.text forKey:@"code"];
    [parameters setObject:confirmTableKeyTextField.text forKey:@"code"];
    
    return parameters;
}

- (void)createLightTable {
    if (self.postRequest) return;
    
    NSMutableDictionary *parameters = [self generateParameters];
    if (parameters == nil){
        return;
    }
    if (!nameTextField.text.length){
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
            [self.lightTable setCode:tableKeyTextField.text];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return;
    }
    
    [self doneEditing];
    [ProgressHUD show:[NSString stringWithFormat:@"Creating \"%@\"",nameTextField.text]];
    self.postRequest = [manager POST:@"light_tables" parameters:@{@"light_table":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success creating a light table: %@", responseObject);
        self.lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        [self.lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];

        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didCreateLightTable:)]){
                [self.lightTableDelegate didCreateLightTable:self.lightTable];
            }
            [ProgressHUD dismiss];
            self.postRequest = nil;
            [self dismissViewControllerAnimated:YES completion:NULL];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"Sorry, but there's already another light table using that key code.\n\nPlease choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error creating a light table: %@",error.description);
        }
        self.postRequest = nil;
    }];
}

- (void)saveLightTable {
    if (self.postRequest) return;
    
    [self doneEditing];
    NSMutableDictionary *parameters = [self generateParameters];
    if (tableKeyTextField.text.length){
        if ([tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [parameters setObject:tableKeyTextField.text forKey:@"code"];
            [self.lightTable setCode:tableKeyTextField.text];
        } else {
            [WFAlert show:@"Please ensure that your light table keys match before continuing." withTime:3.3f];
            return;
        }
    } else {
        [WFAlert show:@"Please ensure you've added a light table key before continuing." withTime:3.3f];
        return;
    }
    if (!nameTextField.text.length){
        [WFAlert show:@"Please make sure you've included a name for your light table before continuing." withTime:3.3f];
        return;
    }
    
    [ProgressHUD show:@"Saving light table..."];
    self.postRequest = [manager PATCH:[NSString stringWithFormat:@"light_tables/%@",self.lightTable.identifier] parameters:@{@"light_table":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success saving a light table: %@", responseObject);
        [self.lightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didUpdateLightTable:)]){
                [self.lightTableDelegate didUpdateLightTable:self.lightTable];
            }
            [ProgressHUD dismiss];
            self.postRequest = nil;
            [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        if ([operation.responseString isEqualToString:kExistingLightTable]){
            [WFAlert show:@"Sorry, but there's already another light table using that key code.\n\nPlease choose another."  withTime:3.3f];
        } else {
            NSLog(@"Error saving a light table: %@",error.description);
        }
        self.postRequest = nil;
    }];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kLightTableDescriptionPlaceholder]){
        [textView setText:@""];
        [textView setTextColor:[UIColor whiteColor]];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!textView.text.length){
        [textView setText:kLightTableDescriptionPlaceholder];
        [textView setTextColor:kLightTablePlaceholderTextColor];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        if (textField == nameTextField){
            [descriptionTextView becomeFirstResponder];
        } else if (textField == tableKeyTextField) {
            [confirmTableKeyTextField becomeFirstResponder];
        } else if (textField == confirmTableKeyTextField) {
            [self createLightTable];
        }
        return NO;
    } else {
        
        return YES;
    }
}

- (void)showOwners {
    WFUsersViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Users"];
    [vc setSelectedUsers:self.owners];
    [vc setOwnerMode:YES];
    vc.userDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self doneEditing];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)showMembers {
    WFUsersViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Users"];
    [vc setSelectedUsers:self.users];
    vc.userDelegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [nav.navigationBar setTintColor:[UIColor whiteColor]];
    [self doneEditing];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)lightTableOwnersSelected:(NSOrderedSet *)selectedOwners {
    self.owners = selectedOwners.mutableCopy;
    [self.users addObjectsFromArray:selectedOwners.array]; // ensure owners are also members
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.tableView reloadData];
    }];
}

- (void)usersSelected:(NSOrderedSet *)selectedUsers {
    self.users = selectedUsers.mutableCopy;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.tableView reloadData];
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
    if (self.postRequest) return;
    
    [self.view endEditing:YES];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (tableKeyTextField.text.length){
        [parameters setObject:tableKeyTextField.text forKey:@"code"];
    } else {
        [WFAlert show:@"Please make sure you've entered a valid key before attempting to join a light table" withTime:3.3f];
        return;
    }
    
    [ProgressHUD show:@"Searching for light table..."];
    self.postRequest = [manager POST:@"light_tables/join" parameters:@{@"light_table":parameters, @"user_id":self.currentUser.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Response object for joining a light table: %@",responseObject);
        NSDictionary *lightTableDict = [responseObject objectForKey:@"light_table"];
        self.lightTable = [LightTable MR_findFirstByAttribute:@"identifier" withValue:[lightTableDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!self.lightTable){
            self.lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        
        [self.lightTable populateFromDictionary:lightTableDict];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (self.lightTableDelegate && [self.lightTableDelegate respondsToSelector:@selector(didJoinLightTable:)]){
                [self.lightTableDelegate didJoinLightTable:self.lightTable];
            }
            [ProgressHUD dismiss];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [WFAlert show:[NSString stringWithFormat:@"You just joined \"%@\"",self.lightTable.name] withTime:3.3f];
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
        self.postRequest = nil;
    }];
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

- (void)textFieldDidChange:(UITextField*)textField {
    [self checkFormStatus];
}

- (void)checkFormStatus {
    if (_joinMode){
        if (tableKeyTextField.text.length){
            [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
            self.actionButton.enabled = YES;
        } else {
            [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
            self.actionButton.enabled = NO;
        }
    } else {
        self.actionButton.enabled = YES;
        if (nameTextField.text.length && tableKeyTextField.text.length && [tableKeyTextField.text isEqualToString:confirmTableKeyTextField.text]){
            [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.33]];
        } else {
            [self.actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
        }
    }
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
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight, 0);
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
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
                     } completion:nil];
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
    [self.mainRequest cancel];
    self.mainRequest = nil;
    [self.postRequest cancel];
    self.postRequest = nil;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
