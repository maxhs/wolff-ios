//
//  WFSettingsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSettingsViewController.h"
#import "WFSettingsCell.h"
#import "Institution+helper.h"
#import "UIFontDescriptor+Lato.h"

@interface WFSettingsViewController () <UITextFieldDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *doneEditingButton;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *saveButton;
    UITextField *emailTextField;
}

@end

@implementation WFSettingsViewController

@synthesize currentUser = _currentUser;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Settings";
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    _currentUser = delegate.currentUser;
    
    self.tableView.rowHeight = 60.f;
    
    [self loadUserDetails];
    
    [self registerForKeyboardNotifications];
    [self setUpNavigationButtons];
    
    
}

- (void)setUpNavigationButtons {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"blackX"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoutButton setTitle:@"Log out" forState:UIControlStateNormal];
    [logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [logoutButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLatoBold] size:0]];
    self.tableView.tableFooterView = logoutButton;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 44.f;
}

- (void)loadUserDetails {
    [manager GET:[NSString stringWithFormat:@"%@/users/%@/edit",kApiBaseUrl,_currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success getting user details: %@",responseObject);
        
        [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get user details: %@",error.description);
    }];
}

- (void)saveSettings {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WFSettingsCell *cell = (WFSettingsCell *)[tableView dequeueReusableCellWithIdentifier:@"SettingsCell"];
    [cell.textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    
    switch (indexPath.row) {
        case 0:
            [cell.textField setText:_currentUser.firstName];
            [cell.textField setPlaceholder:@"First name"];
            break;
        case 1:
            [cell.textField setText:_currentUser.lastName];
            [cell.textField setPlaceholder:@"Last name"];
            break;
        case 2:
            [cell.textField setText:_currentUser.email];
            [cell.textField setPlaceholder:@"Email"];
            break;
        case 3:
            [cell.textField setText:_currentUser.phone];
            [cell.textField setPlaceholder:@"Phone number"];
            break;
        case 4:
            [cell.textField setText:_currentUser.institution.name];
            [cell.textField setPlaceholder:@"Affiliated institution (if any)"];
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (!doneEditingButton) {
        doneEditingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing)];
    }
    
    self.navigationItem.rightBarButtonItem = doneEditingButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    return YES;
}

- (void)doneEditing {
    [self.view endEditing:YES];
}

- (void)logout {
    [self cleanAndResetDB];
    NSLog(@"Log out!");
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [NSUserDefaults resetStandardUserDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self dismiss];
    
    [ProgressHUD dismiss];
}

- (void)cleanAndResetDB {
    NSError *error = nil;
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]];
    [MagicalRecord cleanUp];
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]){
        [MagicalRecord setupAutoMigratingCoreDataStack];
    } else{
        NSLog(@"Error deleting persistent store description: %@ %@", error.description,storeURL);
    }
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    NSValue *keyboardValue = info[UIKeyboardFrameBeginUserInfoKey];
    CGFloat keyboardHeight = keyboardValue.CGRectValue.size.height;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
                     }
                     completion:nil];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
